# Part 17 — Notifications

A pipeline nobody watches is useless if it fails silently. Notifications close the loop: the team
learns the outcome **without** sitting on the Actions tab. This part covers Slack, Teams, and email,
and the three message types that matter.

## 17.1 Why, and the golden rule

```
 build finishes ─▶ notify ─▶ humans react
                              ✅ proceed   ❌ someone fixes it now
```

**Golden rule: notify on failure, always.** Success notifications are optional (some find them
noisy); **failure notifications are mandatory** — a red build no one sees is a broken main that
festers. In YAML this is the `if: always()` habit (Parts 5, 15) so the notify step runs even after
a failed step.

## 17.2 The three message types

| Type | When | Audience | Channel |
|------|------|----------|---------|
| **Success** | green CI / beta uploaded | the author / team | optional, low-noise channel |
| **Failure** | any job fails | the author + on-call | mandatory, visible channel |
| **Deployment** | beta on TestFlight / submitted to App Store | broader team, QA, PM | release channel |

Keep each message **actionable**: status, what (context + build #), where (link to the run), which
(branch/commit). Our `notify_slack.sh` (Part 15) already encodes status→emoji/color + a run link.

## 17.3 Slack (Incoming Webhook)

Simplest: a webhook URL stored as a secret (`SLACK_WEBHOOK`, Part 10), POST JSON to it.

[`Scripts/notify_slack.sh`](../../Scripts/notify_slack.sh) (committed) — usage in any workflow:
```yaml
- name: Notify Slack
  if: always()                                   # report success AND failure
  run: ./Scripts/notify_slack.sh "${{ job.status }}" "TestFlight beta (build ${{ github.run_number }})"
  env:
    SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
```
The script maps `success/failure/cancelled` → color+emoji and includes a `View run` link + branch +
short SHA. It's **best-effort** (`|| echo …`) so a Slack hiccup never fails your build.

Alternative: the official `slackapi/slack-github-action` for richer Block Kit messages.

## 17.4 Microsoft Teams

Same idea, different payload shape (MessageCard / Adaptive Card) and an **Incoming Webhook**
connector URL stored as `TEAMS_WEBHOOK`:
```yaml
- name: Notify Teams
  if: failure()                                  # e.g. failures-only to Teams
  run: |
    curl -sf -H 'Content-Type: application/json' -d '{
      "@type":"MessageCard","themeColor":"D92D20",
      "title":"❌ Build failed",
      "text":"'"${GITHUB_REF_NAME}"' @ '"${GITHUB_SHA:0:7}"'",
      "potentialAction":[{"@type":"OpenUri","name":"View run",
        "targets":[{"os":"default","uri":"'"${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"'"}]}]
    }' "$TEAMS_WEBHOOK"
  env: { TEAMS_WEBHOOK: ${{ secrets.TEAMS_WEBHOOK }} }
```

## 17.5 Email

Two easy routes:
- **GitHub's built-in notifications** — watchers/authors already get emails on workflow failure
  (Settings → Notifications → Actions). Zero config; good baseline.
- **Explicit email action** (e.g. `dawidd6/action-send-mail`) via SMTP secrets, for sending to a
  distribution list / external stakeholders:
```yaml
- uses: dawidd6/action-send-mail@v3
  if: failure()
  with:
    server_address: smtp.example.com
    server_port: 465
    username: ${{ secrets.SMTP_USER }}
    password: ${{ secrets.SMTP_PASS }}
    subject: "❌ ${{ github.repository }} build failed"
    to: ios-team@example.com
    from: ci@example.com
    body: "Run: ${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}"
```

## 17.6 Targeting the right people
- **`if: failure()`** for failure-only channels; **`if: always()`** when one step reports both
  outcomes (read `job.status` inside).
- Mention the **author** on failure (`github.actor`) so it's not diffuse "someone's problem."
- Route by event: PR failures → the dev channel; `release.yml` → a release channel + PM.
- Centralize in Fastlane's `after_all`/`error` hooks (Part 8) **or** a final workflow step — pick
  one so messages aren't duplicated.

## 17.7 Common mistakes
- **Notify only on success** → failures are invisible; the whole point is lost.
- **Notify step without `if: always()`/`failure()`** → it's skipped exactly when a prior step
  failed.
- **Letting a notify failure fail the build** → make it best-effort (`|| true`).
- **Hardcoding the webhook URL** → it's a secret; leaking it lets anyone spam your channel.
- **Too-noisy success pings** → people mute the channel, then miss failures. Tune volume.

## 17.8 Debugging
- Test the webhook locally: `SLACK_WEBHOOK=… ./Scripts/notify_slack.sh success "local test"`.
- No message → check the secret is set for that job and the step's `if:` matched.
- Slack 404/invalid_payload → malformed JSON; echo the payload (not the URL) and validate.

## 17.9 Best practices
- **Failure notifications mandatory + actionable + best-effort.**
- **One source of notifications** (workflow step *or* Fastlane hook), not both.
- **Link back to the run** and include branch/commit/build number.
- **Route by severity/audience**; keep success low-noise.
- **Webhooks are secrets**; rotate if leaked (Part 23).

---

**Next:** [Part 18 — Rollback Strategy](part-18-rollback.md).
