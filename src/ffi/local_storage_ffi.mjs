import { Ok, Error } from "../gleam.mjs";

export function setItem(key, value) {
  try {
    localStorage.setItem(key, value);
    return new Ok(null);
  } catch {
    return new Error(null);
  }
}
