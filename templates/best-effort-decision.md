# Best-Effort Decision (professional review queue entry)

Use this when a decision needs a professional (lawyer, domain specialist, auditor) who hasn't been
engaged yet. Don't park the work: make the most conservative decision the primary source supports,
ship it, and add this entry as a comment on that profession's single living review ticket. Keep one
living ticket per profession; don't open a new one per question.

What stays gated on a real review: marking the content "reviewed", and anything that claims legal
force. Never record a reviewer, or a sign-off, that didn't happen.

---

### Best-effort decision: <short title>

- **Question:** <What needed a professional's judgement.>
- **Decision taken:** <The reading we implemented.>
- **Basis:** <Instrument, edition, and section or clause actually read. Quote the operative words.>
- **Why this reading:** <Why it's the conservative choice, e.g. a "should" treated as required.>
- **Where it lives:** <File or record, and the PR that shipped it.>
- **If the reviewer disagrees:** <Exactly what changes, and roughly how big the change is.>
- **Status:** best effort · not reviewed · `reviewed_by` is empty

---

Record the same status next to the content itself, for example:

```json
{
  "review_status": "best_effort",
  "basis": "Guidance section 4.2 says 'should'; stricter reading chosen",
  "reviewed_by": null
}
```
