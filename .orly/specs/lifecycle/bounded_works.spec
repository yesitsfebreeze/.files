require: checks.bounded_works.exit equals 0

The `bounded` helper passes exit status through, returns 124 at its deadline, and leaves no process of the group alive either way.
