/// Policies for how the database is migrated between web storage backends.
library;

/// When the browser supports OPFS (cross-origin isolation via the service
/// worker), move an existing IndexedDB-backed database to OPFS in instead of
/// abandoning it. Drift does this natively via `WasmDatabase.open` when
/// `moveExistingIndexedDbToOpfs` is set; this constant is the single source of
/// truth for that flag so tests can pin the policy.
const bool moveLegacyIndexedDbToOpfs = true;
