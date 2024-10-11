import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import routine.{type Routine, type Step, Routine, Step}

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

// type Step {
//   Step(id: String, text: String, minutes_before: Int)
// }
//
// type Routine {
//   Routine(id: String, steps: List(Step))
// }

type Page {
  Home
  CreateRoutine
  EditRoutine(Routine)
  RunRoutine
}

type Modal {
  AddStepModal(Step)
}

type Model {
  Model(
    current_page: Page,
    routines: List(Routine),
    visible_steps: List(Step),
    visible_modal: Option(Modal),
  )
}

type Msg {
  UserClickedAddRoutine
  UserAddedRoutine(Routine)
  UserUpdatedRoutine(Routine)
  UserRemovedRoutine(Routine)
  UserClickedRoutine(Routine)

  UserClickedAddStep
  UserChangedAddStepModalText(String)
  UserChangedAddStepModalTimeValue(Int)
  UserGaveIncorrectAddStepModalInput
  UserAddedOrUpdatedStep(Step)
  UserClickedStep(Step)
  UserRemovedStep(Step)
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  routine.routines_to_json([
    Routine(id: "21", steps: [
      Step("asdf", "I'm a step, this is my description", 2137),
      Step("ff", "I'm a step, this is my description aaaa", 2137),
      Step("aa", "I'm a step, this is my description 23", 2137),
    ]),
    Routine(id: "23", steps: [
      Step("ff", "I'm a step, this is my description aaaa", 2137),
      Step("aa", "I'm a step, this is my description 23", 2137),
    ]),
  ])
  |> io.debug()
  |> routine.routines_from_json()
  |> io.debug()
  // let step_json =
  //   routine.step_to_json(Step(
  //     "asdf",
  //     "I'm a step, this is my description",
  //     2137,
  //   ))
  // io.debug(step_json)
  // routine.step_from_json(step_json)
  #(Model(Home, [], [], None), effect.none())
}

fn new_element_id(elements: List(_)) -> String {
  elements |> list.length() |> int.to_string()
}

fn get_updated_elements(
  elements: List(a),
  get_element_id: fn(a) -> String,
  new_element: a,
  new_element_id: String,
) -> List(a) {
  list.map(elements, fn(element) {
    case get_element_id(element) == new_element_id {
      True -> new_element
      False -> element
    }
  })
}

fn get_updated_routines(
  routines: List(Routine),
  new_routine: Routine,
) -> List(Routine) {
  get_updated_elements(routines, fn(r) { r.id }, new_routine, new_routine.id)
}

fn get_updated_steps(steps: List(Step), new_step: Step) -> List(Step) {
  get_updated_elements(steps, fn(r) { r.id }, new_step, new_step.id)
}

fn get_added_or_updated_steps(steps: List(Step), new_step: Step) -> List(Step) {
  let updated_steps = get_updated_steps(steps, new_step)
  case updated_steps == steps {
    True -> [new_step, ..steps]
    False -> updated_steps
  }
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserAddedRoutine(routine) -> #(
      Model(
        ..model,
        current_page: Home,
        routines: [routine, ..model.routines],
        visible_steps: [],
      ),
      effect.none(),
    )
    UserUpdatedRoutine(routine) -> {
      io.debug(model.routines)
      io.debug(routine)
      io.debug(get_updated_elements(
        model.routines,
        fn(r) { r.id },
        routine,
        routine.id,
      ))
      #(
        Model(
          ..model,
          current_page: Home,
          routines: get_updated_routines(model.routines, routine),
          visible_steps: [],
        ),
        effect.none(),
      )
    }
    UserRemovedRoutine(removed_routine) -> #(
      Model(
        ..model,
        routines: list.filter(model.routines, fn(routine) {
          routine.id != removed_routine.id
        }),
      ),
      effect.none(),
    )
    UserClickedAddRoutine -> #(
      Model(..model, current_page: CreateRoutine),
      effect.none(),
    )
    UserClickedAddStep -> #(
      Model(
        ..model,
        visible_modal: Some(
          AddStepModal(Step(new_element_id(model.visible_steps), "", 0)),
        ),
      ),
      effect.none(),
    )
    UserChangedAddStepModalTimeValue(time_value) -> #(
      Model(
        ..model,
        visible_modal: option.map(model.visible_modal, fn(modal) {
          case modal {
            AddStepModal(step) ->
              AddStepModal(Step(..step, minutes_before: time_value))
          }
        }),
      ),
      effect.none(),
    )
    UserGaveIncorrectAddStepModalInput -> {
      let model_copy = model
      #(model_copy, effect.none())
    }
    UserChangedAddStepModalText(text) -> #(
      Model(
        ..model,
        visible_modal: option.map(model.visible_modal, fn(modal) {
          case modal {
            AddStepModal(step) -> AddStepModal(Step(..step, text:))
          }
        }),
      ),
      effect.none(),
    )
    UserAddedOrUpdatedStep(step) -> {
      #(
        Model(
          ..model,
          visible_steps: get_added_or_updated_steps(model.visible_steps, step),
          visible_modal: None,
        ),
        effect.none(),
      )
    }
    UserClickedRoutine(routine) -> #(
      Model(
        ..model,
        current_page: EditRoutine(routine),
        visible_steps: routine.steps,
      ),
      effect.none(),
    )
    UserClickedStep(step) -> #(
      Model(..model, visible_modal: Some(AddStepModal(step))),
      effect.none(),
    )
    UserRemovedStep(removed_step) -> #(
      Model(
        ..model,
        visible_steps: list.filter(model.visible_steps, fn(step) {
          step.id != removed_step.id
        }),
      ),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div(
    [attribute.class("container h-screen overflow-auto mx-auto border-x p-4")],
    [
      case model.current_page {
        Home -> view_home(model)
        CreateRoutine -> view_create_routine(model)
        EditRoutine(routine) -> view_edit_routine(model, routine)
        RunRoutine -> todo
      },
    ],
  )
}

fn view_home(model: Model) -> Element(Msg) {
  let tiles =
    model.routines
    |> list.map(fn(routine) { routine_tile(routine) })
    |> list.reverse()

  html.div([], [
    html.button(
      [
        attribute.class(
          "absolute inset-x-0 bottom-4 mx-auto w-16 h-16 border rounded-full p-4 text-2xl hover:bg-gray-500",
        ),
        event.on_click(UserClickedAddRoutine),
      ],
      [element.text("+")],
    ),
    ..tiles
  ])
}

fn view_create_routine(model: Model) -> Element(Msg) {
  [
    event.on_click(
      UserAddedRoutine(Routine(
        id: new_element_id(model.routines),
        steps: model.visible_steps,
      )),
    ),
  ]
  |> routine_editor(model, _, "create routine")
}

fn view_edit_routine(model: Model, edited_routine: Routine) -> Element(Msg) {
  let handle_commit = fn(event: Dynamic) -> Result(Msg, List(DecodeError)) {
    use target <- result.try(dynamic.field("target", dynamic.dynamic)(event))
    use value <- result.try(dynamic.field("value", dynamic.string)(target))
    Ok(UserUpdatedRoutine(Routine(id: value, steps: model.visible_steps)))
  }
  [attribute.value(edited_routine.id), event.on("click", handle_commit)]
  |> routine_editor(model, _, "update routine")
}

fn routine_editor(
  model: Model,
  commit_routine_attrs: List(Attribute(Msg)),
  commit_routine_label: String,
) -> Element(Msg) {
  let step_tiles = list.map(model.visible_steps, fn(step) { step_tile(step) })
  let modal = case model.visible_modal {
    Some(AddStepModal(step)) -> add_step_modal(step)
    None -> element.none()
  }

  html.div([], [
    modal,
    html.button(commit_routine_attrs, [element.text(commit_routine_label)]),
    html.button([event.on_click(UserClickedAddStep)], [
      element.text("create step"),
    ]),
    ..step_tiles
  ])
}

fn routine_tile(routine: Routine) -> Element(Msg) {
  let text = "This tile has id of " <> routine.id
  tile(text, UserClickedRoutine(routine), UserRemovedRoutine(routine))
}

fn step_tile(step: Step) -> Element(Msg) {
  let text = step.text <> " | -" <> int.to_string(step.minutes_before) <> "min"
  tile(text, UserClickedStep(step), UserRemovedStep(step))
}

fn tile(text: String, edit_msg: m, remove_msg: m) -> Element(m) {
  let handle_click = fn(event) {
    event.stop_propagation(event)
    Ok(remove_msg)
  }

  html.div(
    [
      event.on_click(edit_msg),
      attribute.class("flex justify-between text-2xl border rounded p-4 mb-4"),
    ],
    [
      element.text(text),
      html.button([event.on("click", handle_click), attribute.class("border")], [
        element.text("X"),
      ]),
    ],
  )
}

fn add_step_modal(step: Step) -> Element(Msg) {
  let handle_time_input = fn(input) {
    case int.parse(input) {
      Ok(value) -> UserChangedAddStepModalTimeValue(value)
      _ -> UserGaveIncorrectAddStepModalInput
    }
  }
  html.div(
    [
      attribute.class(
        "absolute inset-0 z-10 flex justify-center items-center h-screen",
      ),
    ],
    [
      html.div([attribute.class("h-max w-max p-4 border rounded")], [
        element.text("I need to "),
        html.input([
          event.on_input(UserChangedAddStepModalText),
          attribute.class(""),
          attribute.type_("text"),
          attribute.value(step.text),
          attribute.min("0"),
        ]),
        html.br([]),
        html.input([
          event.on_input(handle_time_input),
          attribute.class("w-12"),
          attribute.type_("number"),
          attribute.value(int.to_string(step.minutes_before)),
          attribute.min("0"),
        ]),
        element.text(" minutes before"),
        html.button([event.on_click(UserAddedOrUpdatedStep(step))], [
          element.text("Ok"),
        ]),
      ]),
    ],
  )
}
