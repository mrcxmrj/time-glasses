import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import lustre
import lustre/attribute.{type Attribute}
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Step {
  Step(text: String, minutes_before: Int)
}

type Routine {
  Routine(id: String, steps: List(Step))
}

type Page {
  Home
  CreateRoutine
  EditRoutine(Routine)
  RunRoutine
}

type Modal {
  AddStepModal
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
  UserAddedStep(Step)
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(Model(Home, [], [], None), effect.none())
}

fn get_updated_routines(
  routines: List(Routine),
  new_routine: Routine,
) -> List(Routine) {
  list.map(routines, fn(routine) {
    case routine.id == new_routine.id {
      True -> new_routine
      False -> routine
    }
  })
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
    UserUpdatedRoutine(routine) -> #(
      Model(
        ..model,
        current_page: Home,
        routines: get_updated_routines(model.routines, routine),
        visible_steps: [],
      ),
      effect.none(),
    )
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
      Model(..model, visible_modal: Some(AddStepModal)),
      effect.none(),
    )
    UserAddedStep(step) -> #(
      Model(..model, visible_steps: [step, ..model.visible_steps]),
      effect.none(),
    )
    UserClickedRoutine(routine) -> #(
      Model(
        ..model,
        current_page: EditRoutine(routine),
        visible_steps: routine.steps,
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
        id: model.routines |> list.length() |> int.to_string(),
        steps: model.visible_steps,
      )),
    ),
  ]
  |> routine(model, _, "create routine")
}

fn view_edit_routine(model: Model, edited_routine: Routine) -> Element(Msg) {
  let handle_commit = fn(event: Dynamic) -> Result(Msg, List(DecodeError)) {
    use target <- result.try(dynamic.field("target", dynamic.dynamic)(event))
    use value <- result.try(dynamic.field("value", dynamic.string)(target))
    Ok(UserUpdatedRoutine(Routine(id: value, steps: model.visible_steps)))
  }
  [attribute.value(edited_routine.id), event.on("click", handle_commit)]
  |> routine(model, _, "update routine")
}

fn routine(
  model: Model,
  commit_routine_attrs: List(Attribute(Msg)),
  commit_routine_label: String,
) -> Element(Msg) {
  let step_tiles = list.map(model.visible_steps, fn(step) { step_tile(step) })

  html.div([], [
    html.button(commit_routine_attrs, [element.text(commit_routine_label)]),
    html.button(
      [
        event.on_click(
          UserAddedStep(Step(text: "do sth", minutes_before: 2137)),
        ),
      ],
      [element.text("create step")],
    ),
    ..step_tiles
  ])
}

fn routine_tile(routine: Routine) -> Element(Msg) {
  let text = "This tile has id of " <> routine.id
  let handle_click = fn(event) {
    event.stop_propagation(event)
    Ok(UserRemovedRoutine(routine))
  }

  html.div(
    [
      event.on_click(UserClickedRoutine(routine)),
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

fn step_tile(step: Step) -> Element(Msg) {
  let text = step.text <> " | -" <> int.to_string(step.minutes_before) <> "min"

  html.div(
    [attribute.class("flex justify-between text-2xl border rounded p-4 mb-4")],
    [element.text(text)],
  )
}
