// §head home/dot_config/television/theme-preview-sample.ts:8-14 apply
// §sig async function apply(id: string): Promise<Scheme>
  const raw = await readFile(`schemes/${id}.yaml`, "utf8");
  if (!raw) throw new Error(`missing scheme: ${id}`);

  const colors = raw.match(/#[0-9a-f]{6}/gi) ?? [];
  return { name: id, variant: colors.length > 8 ? "dark" : "light" };
// §foot home/dot_config/television/theme-preview-sample.ts apply