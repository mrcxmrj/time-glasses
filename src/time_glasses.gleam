import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

pub type Routine {
  Routine(length: Int)
}

pub type Model {
  Model(routines: List(Routine))
}

pub type Msg

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(Model([]), effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  #(Model([]), effect.none())
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.class("container h-screen mx-auto border-x p-4")], [
    tile(),
    add_button(),
  ])
}

fn tile() -> Element(a) {
  html.div([attribute.class("text-2xl border rounded p-4")], [
    element.text("Hello, time glasses!"),
  ])
}

fn add_button() -> Element(a) {
  html.button([attribute.class("w-sm border rounded-full")], [element.text("+")])
}
