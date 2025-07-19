import ffi/local_storage
import gleam/dynamic/decode.{type Decoder}
import gleam/io
import gleam/json.{type DecodeError, type Json}
import gleam/list
import gleam/result

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
  let step_decoder = {
    use id <- decode.field("id", decode.string)
    use text <- decode.field("text", decode.string)
    use minutes_before <- decode.field("minutes_before", decode.int)
    decode.success(Step(id:, text:, minutes_before:))
  }
  decode.list(step_decoder)
}

fn routines_decoder() -> Decoder(List(Routine)) {
  let routine_decoder = {
    use id <- decode.field("id", decode.string)
    use steps <- decode.field("steps", steps_decoder())
    decode.success(Routine(id:, steps:))
  }
  decode.list(routine_decoder)
}

pub fn routines_from_json(
  json_string: String,
) -> Result(List(Routine), DecodeError) {
  json.parse(json_string, routines_decoder())
}

pub fn save_routines(routines: List(Routine)) -> Result(Nil, Nil) {
  routines
  |> routines_to_json()
  |> local_storage.set_item("routines", _)
}

type GetSavedRoutinesError {
  DecodeError(DecodeError)
  LocalStorageError(Nil)
}

pub fn get_saved_routines() -> List(Routine) {
  let result =
    local_storage.get_item("routines")
    |> result.map_error(LocalStorageError)
    |> result.try(fn(r) {
      routines_from_json(r) |> result.map_error(DecodeError)
    })
  case result {
    Ok(routines) -> routines
    Error(DecodeError(_)) -> {
      io.print_error("Error decoding routines")
      []
    }
    Error(LocalStorageError(Nil)) -> {
      io.print_error("Error reading from local storage")
      []
    }
  }
}
