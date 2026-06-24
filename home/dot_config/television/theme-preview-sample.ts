// theme preview sample — exercises every token color a scheme defines.
import { readFile } from "node:fs/promises";

const MAX_RETRIES = 3; // numbers, constants
type Scheme = { name: string; variant: "dark" | "light" };

/** Load a scheme and tint the terminal. */
export async function apply(id: string): Promise<Scheme> {
  const raw = await readFile(`schemes/${id}.yaml`, "utf8");
  if (!raw) throw new Error(`missing scheme: ${id}`);

  const colors = raw.match(/#[0-9a-f]{6}/gi) ?? [];
  return { name: id, variant: colors.length > 8 ? "dark" : "light" };
}

for (let i = 0; i < MAX_RETRIES; i++) {
  console.log(`attempt ${i + 1} — keywords, strings, numbers & comments`);
}
