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

pub type Model {
  Model(routines: List(Routine))
}

pub type Msg {
  UserAddedRoutine
  UserRemovedRoutine(id: Int)
}

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(Model([]), effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserAddedRoutine -> #(
      Model(routines: [Routine(list.length(model.routines)), ..model.routines]),
      effect.none(),
    )
    UserRemovedRoutine(id) -> #(
      Model(
        routines: list.filter(model.routines, fn(routine) { routine.id != id }),
      ),
      effect.none(),
    )
  }
}

fn view(model: Model) -> Element(Msg) {
  let tiles =
    list.map(model.routines, fn(routine) {
      tile("This tile has id of " <> int.to_string(routine.id), routine.id)
    })

  html.div(
    [attribute.class("container h-screen overflow-auto mx-auto border-x p-4")],
    [
      html.button(
        [
          attribute.class(
            "absolute inset-x-0 bottom-4 mx-auto w-16 h-16 border rounded-full p-4 text-2xl hover:bg-gray-500",
          ),
          event.on_click(UserAddedRoutine),
        ],
        [element.text("+")],
      ),
      ..tiles
    ],
  )
}

fn tile(text: String, id: Int) -> Element(Msg) {
  html.div(
    [attribute.class("flex justify-between text-2xl border rounded p-4 mb-4")],
    [
      element.text(text),
      html.button([event.on_click(UserRemovedRoutine(id))], [element.text("X")]),
    ],
  )
}
