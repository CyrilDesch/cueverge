// @what: one round. The verdicts of every case, and what the runner shows.
// @invariant: nothing here can fail. A refused round has verdicts too. The seal rules decide.
package rules

import "list"

#Round: {
	initiative: #Initiative
	observed:   #Observed
	sealed: [string]: #Verdict
	// @what: what the last generation claims, and the hash a person approved.
	declared: #Intent
	approval: string | *""

	verdicts: {for k, a in observed {
		(k): (#Judge & {
			o:        a.oracle...
			c:        a.candidate...
			judge:    initiative.judge...
			budgetMs: initiative.candidate.budgetMs...
		}).verdict...
	}}

	// @what: what the runner prints and acts on. The runner holds no verdict logic, it reads these lists.
	summary: {
		cases: len(verdicts)
		count: [for v in verdictOrder {
			verdict: v
			n: len([for _, x in verdicts if x == v {
				x...
			}])
		}]
		_valid: [for k, a in observed if a.oracle.exit == 0 {
			k...
		}]
		valid: len(_valid)
		validCorrect: len([for k in _valid if list.Contains(passing, verdicts[k]) {
			k...
		}])
		failing: list.SortStrings([for k, v in verdicts if !list.Contains(passing, v) {
			k...
		}])
		// @what: the cases to time again.
		late: list.SortStrings([for k, v in verdicts if v == "late" {
			k...
		}])
		// @what: passed in the sealed round, and fail now or have no verdict. Shown here, decided by the seal rules.
		_passingNow: [for k, v in verdicts if list.Contains(passing, v) {
			k...
		}]
		regressed: list.SortStrings([for k, v in sealed
		if list.Contains(passing, v) && !list.Contains(_passingNow, k) {
			k...
		}])
	}

	intent: #IntentReview & {
		policy: [if initiative.generator != _|_ {
			initiative.generator.intent...
		}, #IntentPolicy][0]
		"intent":   declared
		"approval": approval
		"verdicts": verdicts
		"sealed":   sealed
		regressed:  summary.regressed
	}
}
