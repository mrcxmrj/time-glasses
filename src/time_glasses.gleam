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

pub type Routine {
  Routine(id: Int)
}

type Page {
  Home
  CreateRoutine
  RunRoutine
}

type Model {
  Model(current_page: Page, routines: List(Routine))
}

type Msg {
  UserAddedRoutine
  UserRemovedRoutine(Routine)
  UserClickedAddRoutine
  UserClickedRoutine(Routine)
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(Model(Home, []), effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserAddedRoutine -> #(
      Model(current_page: Home, routines: [
        Routine(list.length(model.routines)),
        ..model.routines
      ]),
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
    _ -> #(model, effect.none())
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
  let tiles =
    list.map(model.routines, fn(routine) {
      routine_tile("This tile has id of " <> int.to_string(routine.id), routine)
    })

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
  html.div([], [
    html.button([event.on_click(UserAddedRoutine)], [element.text("create")]),
  ])
}

fn routine_tile(text: String, routine: Routine) -> Element(Msg) {
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
