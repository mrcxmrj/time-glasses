import gleam/int
import gleam/list
import lustre
import lustre/attribute
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
  Routine(id: Int, steps: List(Step))
}

type Page {
  Home
  CreateRoutine
  RunRoutine
}

type Model {
  Model(current_page: Page, routines: List(Routine), visible_steps: List(Step))
}

type Msg {
  UserAddedRoutine(Routine)
  UserRemovedRoutine(Routine)
  UserClickedAddRoutine
  // UserClickedRoutine(Routine)
  UserAddedStep(Step)
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(Model(Home, [], []), effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserAddedRoutine(routine) -> #(
      Model(
        current_page: Home,
        routines: [routine, ..model.routines],
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
    UserAddedStep(step) -> #(
      Model(..model, visible_steps: [step, ..model.visible_steps]),
      effect.none(),
    )
    // _ -> #(model, effect.none())
    // UserClickedRoutine(routine) -> #(
    //   Model(..model, current_page: CreateRoutine),
    //   effect.none(),
    // )
  }
}

fn view(model: Model) -> Element(Msg) {
  html.div(
    [attribute.class("container h-screen overflow-auto mx-auto border-x p-4")],
    [
      case model.current_page {
        Home -> view_home(model)
        CreateRoutine -> view_create_routine(model)
        _ -> element.text("not implemented")
      },
    ],
  )
}

fn view_home(model: Model) -> Element(Msg) {
  let tiles = list.map(model.routines, fn(routine) { routine_tile(routine) })

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
  let step_tiles = list.map(model.visible_steps, fn(step) { step_tile(step) })

  html.div([], [
    html.button(
      [
        event.on_click(
          UserAddedRoutine(Routine(
            id: list.length(model.routines),
            steps: model.visible_steps,
          )),
        ),
      ],
      [element.text("create routine")],
    ),
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
  let text = "This tile has id of " <> int.to_string(routine.id)
  html.div(
    [attribute.class("flex justify-between text-2xl border rounded p-4 mb-4")],
    [
      element.text(text),
      html.button([event.on_click(UserRemovedRoutine(routine))], [
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
