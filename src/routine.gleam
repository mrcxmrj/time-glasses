import ffi/local_storage
import gleam/dynamic.{type Decoder}
import gleam/json.{type DecodeError, type Json}
import gleam/list

pub type Routine {
  Routine(id: String, steps: List(Step))
}

pub type Step {
  Step(id: String, text: String, minutes_before: Int)
}

fn encode_step(step: Step) -> Json {
  json.object([
    #("id", json.string(step.id)),
    #("text", json.string(step.text)),
    #("minutes_before", json.int(step.minutes_before)),
  ])
}

fn encode_routine(routine: Routine) -> Json {
  json.object([
    #("id", json.string(routine.id)),
    #("steps", json.preprocessed_array(list.map(routine.steps, encode_step))),
  ])
}

pub fn routine_to_json(routine: Routine) -> String {
  routine |> encode_routine() |> json.to_string()
}

pub fn routines_to_json(routines: List(Routine)) -> String {
  routines
  |> list.map(encode_routine)
  |> json.preprocessed_array()
  |> json.to_string()
}

fn steps_decoder() -> Decoder(List(Step)) {
  let step_decoder =
    dynamic.decode3(
      Step,
      dynamic.field("id", dynamic.string),
      dynamic.field("text", dynamic.string),
      dynamic.field("minutes_before", dynamic.int),
    )

  dynamic.list(step_decoder)
}

fn routine_decoder() -> Decoder(Routine) {
  dynamic.decode2(
    Routine,
    dynamic.field("id", dynamic.string),
    dynamic.field("steps", steps_decoder()),
  )
}

pub fn routine_from_json(json_string: String) -> Result(Routine, DecodeError) {
  json.decode(json_string, routine_decoder())
}

pub fn routines_from_json(
  json_string: String,
) -> Result(List(Routine), DecodeError) {
  let routines_decoder = dynamic.list(routine_decoder())
  json.decode(json_string, routines_decoder)
}

pub fn save_routines(routines: List(Routine)) -> Result(Nil, Nil) {
  routines
  |> routines_to_json()
  |> local_storage.set_item("routines", _)
}
