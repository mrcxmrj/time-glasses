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

pub type Model {
  Model
}

pub type Msg

fn init(_flags) -> #(Model, Effect(Msg)) {
  #(Model, effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  #(Model, effect.none())
}

fn view(model: Model) -> Element(Msg) {
  html.div([attribute.classes([#("text-2xl", True)])], [
    element.text("Hello, time glasses!"),
  ])
}
