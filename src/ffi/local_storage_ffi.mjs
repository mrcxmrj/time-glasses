import { Ok, Error } from "../gleam.mjs";

export function setItem(key, value) {
  try {
    localStorage.setItem(key, value);
    return new Ok(null);
  } catch {
    return new Error(null);
  }
}

export function getItem(key) {
  try {
    const item = localStorage.getItem(key);
    return item !== null ? new Ok(item) : new Error(null);
  } catch {
    return new Error(null);
  }
}
