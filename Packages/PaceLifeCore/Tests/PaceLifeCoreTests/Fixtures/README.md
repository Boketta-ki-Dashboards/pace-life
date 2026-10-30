# Frozen schema-1 migration fixture

`schema-one.json` was written by the actual phase-one `JSONStateRepository.save`
implementation at commit `c2299e5` using Swift 6.0.3. It contains synthetic test
data only: three goal types, an archived habit, a historical target different
from its current target, four completion IDs, two modes, closed and active mode
activations, custom widget order/visibility, and Russian/dark preferences.

Keep these bytes frozen when implementing future schema migrations. Tests must
load this existing representation rather than regenerate it with new models.
The numerical dates use Foundation's default Codable reference-date encoding.

This fixture cannot supply missing schema-1 history: prior weekday changes and
past mode habit memberships were never stored. Migration must explicitly keep
that limitation instead of inventing historical plans.
