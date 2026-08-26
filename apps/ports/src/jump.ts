export function jumpTarget(key: string, count: number): number | null {
  if (count <= 0) return null;
  if (key === "g") return 0;
  if (key === "G") return count - 1;
  return null;
}