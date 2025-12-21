Chaos:
	Epics:
		- planning-system-rollout -> Epics/planning-system-rollout/
		- startup-and-handoff-automation -> Epics/startup-and-handoff-automation/
		- forge-and-repo-hygiene -> Epics/forge-and-repo-hygiene/
		- reporting-and-clio-integration -> Epics/reporting-and-clio-integration/
		- messaging-and-routing -> Epics/messaging-and-routing/
	Today:
		- Verify plan tree scaffold and link targets exist @owner(Chaos)
		- Note Planning.Method in README for quick discoverability @owner(Chaos)
	This Week:
		- planning-system-rollout/cross-persona-template: define per-persona plan template and first adopters @owner(Chaos)
		- startup-and-handoff-automation/plan-ingest-on-startup: design ingestion flow @owner(Chaos)
		- forge-and-repo-hygiene/phyle-bootstrap-hardening: outline next hardening steps @owner(Chaos)
	Backlog:
		- reporting-and-clio-integration/plan-rollups: wire Clio to summarize plan files @owner(Chaos)
		- reporting-and-clio-integration/daily-weekly-reports: choose report cadence and format @owner(Chaos)
	Definitions:
		- DoD: Plan lives under `Plan/`; epics and stories exist and are referenced with matching slugs; tasks carry @owner, time-bounded tasks carry @due; TaskPaper format.
	Constraints:
		- Limited time/energy; daily-commit goal; Roz handles emotional load; keep private items out of git (public-safe tasks only).
