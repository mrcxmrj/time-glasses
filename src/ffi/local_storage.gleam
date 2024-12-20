@external(javascript, "./local_storage_ffi.mjs", "setItem")
pub fn set_item(key: String, value: String) -> Result(Nil, Nil)

@external(javascript, "./local_storage_ffi.mjs", "getItem")
pub fn get_item(key: String) -> Result(String, Nil)
