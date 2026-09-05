export default function StatusBadge({ status }) {
  let badgeClass = "badge-indigo";
  if (!status) return null;

  const normalized = status.toLowerCase();
  if (["active", "verified", "excellent", "generated", "validated & synced", "super admin"].includes(normalized)) {
    badgeClass = "badge-emerald";
  } else if (["high", "very high", "good", "state admin", "syncing (94%)"].includes(normalized)) {
    badgeClass = "badge-cyan";
  } else if (["medium", "average", "pending", "data administrator"].includes(normalized)) {
    badgeClass = "badge-amber";
  } else if (["needs improvement", "inactive", "revoked"].includes(normalized)) {
    badgeClass = "badge-rose";
  }

  return (
    <span className={`badge ${badgeClass}`}>
      {status}
    </span>
  );
}
