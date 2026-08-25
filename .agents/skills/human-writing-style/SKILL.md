---
name: human-writing-style
description: Edit or review prose to remove AI-writing patterns while preserving facts and the author's voice. Use for "sound human", "don't sound like AI", "humanize this", "make this natural", "make it sound like me", and similar rewrite requests. Also use proactively for emails, Slack messages, PR reviews, blog posts, docs, marketing copy, social posts, and other prose where AI-flavored writing would hurt the result. Do NOT use for code, SQL, structured data, JSON, or technical API syntax where exact terms matter.
metadata:
  author: Higgins, adapted from blader/humanizer
  version: 2.0.0
  upstream: blader/humanizer@2.9.1
---

# Human writing style

Humanizer's general editing model with Higgins's stricter reframe and analogy controls. Apply with judgment. Accuracy and the author's voice outrank every style rule.

## Core principle

Preserve the information, remove the AI patterns, and match the intended voice.

AI text regresses to the mean. Specific facts fade into generic praise. Concrete details blur into vague importance. The fix is to stay concrete and direct.

## The clustering rule

The goal is not to avoid every word on the watchlist. The goal is to avoid the patterns: generic over specific, hollow emphasis over concrete facts, formulaic structures over natural variation, asserting significance over showing it.

One "crucial" is fine. "Crucial," "pivotal," "testament," and "landscape" in the same paragraph is a tell. Audit for clustering, not single words.

## How to Use This Skill

When this skill triggers, hold these rules in mind while drafting and run the final pass before sending. Don't paste the rules into the reply or announce that you're following them.

The rules are organized by how often you'll trip on them:

1. **Rule priority** — what to optimize for when rules collide
2. **Default voice** — the baseline
3. **Context modes** — how to adjust for chat vs. published vs. technical
4. **Formatting**
5. **AI-pattern watchlist** — vocabulary, phrase shapes, transitions, hype
6. **Reframe ban** — the most-violated rule, read carefully
7. **Analogy and metaphor control**
8. **Specificity**
9. **AI writing patterns to avoid**
10. **Anti-overfitting** — don't try too hard
11. **Invocation modes** — pasted text, files, and embedded tasks
12. **Final pass** — run before sending

For example pairs and rewrite walkthroughs, see `references/examples-and-rewrites.md`.

---

## 1. Rule priority

When rules collide, use this order:

1. Be accurate.
2. Be clear.
3. Be specific.
4. Sound human.
5. Use style only when it improves the sentence.

Don't follow a style rule so strictly that the result gets awkward.

### Preserve information without inventing it

Every claim in the source must survive unless it is unsupported filler. Paragraph count and sentence structure do not need to survive. Compress dull passages, spend more space on useful details, and split or merge paragraphs as needed.

Never add a fact, name, number, date, quote, or citation that is not in the source or supplied by the user. Specificity must come from the source. If a sentence needs a missing detail, ask for it or write the plain version without it.

---

## 2. Default voice

Write directly, specifically, and naturally.

Start with the useful answer.

Use short paragraphs. 1 or 2 sentences by default. 3 or 4 sometimes.

Vary rhythm. Short sentence. Longer sentence. Fragments are allowed when they sound natural. Don't write in a steady medium-length pattern.

Use contractions naturally: don't, can't, won't, it's, you're.

Use I and you when natural. Talk to people.

Prefer active voice.

Be specific. Use numbers, names, concrete details, dates, places, prices, constraints, tradeoffs, and real examples.

Use plain uncertainty when uncertain: I think, probably, maybe, my read, I'm not sure. Don't use vague hedging to avoid taking a position.

Take a stance when the evidence supports one.

Don't pad output to seem thorough. Short and accurate beats long and padded.

If the point is made, stop.

---

## 3. Context modes

Match the job.

**Chat.** Direct. Warm enough. No assistant performance. Don't say: Certainly, Of course, Happy to help, Great question, I hope this helps, Would you like me to. Ask a follow-up only when the missing detail changes the answer.

**Editing.** Name the problem. Give the fix. Show a better version. Don't praise weak writing before editing it.

**Published writing.** Remove chat phrases. No meta commentary. No explanation of what the piece is about to do.

**Technical writing.** Clarity beats personality. Define terms. Show steps. Avoid decorative language near important details.

**Sensitive topics.** Calm beats punchy. Be direct, gentle, and exact.

**Sales or persuasion.** Proof beats hype. Specific claims beat adjectives.

### Voice calibration

If the user provides a writing sample, read it first. Match its sentence lengths, vocabulary, punctuation, paragraph openings, recurring phrases, and deliberate quirks. Do not upgrade casual language or regularize an intentional style.

The sample outranks this skill's style preferences, including the default em-dash rule. Accuracy and non-fabrication still apply.

### Personality and restraint

For personal writing, essays, blog posts, and opinion, preserve humor, uncertainty, mixed feelings, asides, and uneven rhythm when they belong to the author. For technical, legal, reference, and review prose, neutral and plain is usually the right human voice. Do not inject first person, jokes, or opinions into neutral material.

---

## 4. Formatting

Use formatting only when it improves reading.

Short paragraphs by default.

Use digits for numbers: 3 years, 10 tools, 500 users.

Use no em or en dashes by default. Prefer periods, commas, colons, semicolons, or parentheses. A user-provided writing sample can override this rule.

Bold sparingly. 1 or 2 moments per section max.

Use headers only when they help.

Use bullets only when scanning matters.

Use code blocks for exact prompts, commands, examples, or copy.

Use sentence case in headers.

Don't add a summary paragraph unless the piece is long enough to need one.

---

## 5. AI-pattern watchlist

These patterns often make text sound machine-written, over-polished, or falsely deep. Treat them as evidence, not automatic defects. Preserve exact technical terms, quotations, proper names, and vocabulary that matches the author's sample. Rewrite when several tells cluster or when a phrase adds no information.

### 5A. Vocabulary to watch

delve, realm, harness, unlock, tapestry, paradigm, cutting-edge, revolutionize, intricate, intricacies, showcasing, crucial, pivotal, surpass, meticulously, vibrant, unparalleled, underscore, leverage, synergy, innovative, game-changer, testament, commendable, meticulous, highlight, emphasize, boast, groundbreaking, align, foster, showcase, enhance, holistic, garner, accentuate, pioneering, trailblazing, unleash, versatile, transformative, redefine, seamless, optimize, scalable, robust, breakthrough, empower, streamline, frictionless, elevate, adaptive, effortless, data-driven, insightful, proactive, mission-critical, visionary, disruptive, reimagine, unprecedented, intuitive, leading-edge, synergize, democratize, accelerate, state-of-the-art, dynamic, immersive, predictive, transparent, proprietary, integrated, plug-and-play, turnkey, future-proof, paradigm-shifting, supercharge, enduring, interplay, valuable, captivate

### 5B. Bloated phrase shapes

Don't use bloated verbs to dodge `is` or `has`.

Bad: serves as, stands as, marks a, represents a, boasts a, features a, offers a, plays a role in, helps to, aims to, seeks to.

Use the plain verb: is, has, uses, gives, shows, causes, changes, removes, adds.

### 5C. Dead openings and phrases

Don't use:

In today's..., It is important to note that..., It is worth noting..., In order to, Let's dive in, Let's explore, Let's unpack, At the end of the day, Moving forward, To put this in perspective, What makes this particularly interesting is, The implications here are, In other words, It goes without saying, Nobody is talking about, Most people don't realize, In this article I will, Despite its strengths X faces challenges, Challenges and future prospects, navigate the complexities of, in an ever-changing landscape.

### 5D. Mechanical transitions

Watch for: Furthermore, Additionally, Moreover, That said, That being said, With that in mind, It is also worth mentioning, On top of that, Importantly.

One can be natural. Several stacked across nearby paragraphs are a tell. Use a specific transition or no transition.

### 5E. Engagement bait

Don't use: Let that sink in, Read that again, Full stop, This changes everything, Are you paying attention?, You are not ready for this.

### 5F. Hype language

No promises of superpowers, easy riches, overnight transformation, or magic growth. Don't use: 10x your anything, game-changer, cutting-edge, future-proof, unlock, supercharge.

### 5G. Vague attribution

Don't use vague sources to dodge naming the actual source.

Don't use: Experts argue, Industry observers note, It has been widely recognized, According to sources, Some critics argue, Industry reports suggest, It has been noted.

Either name the source or cut the claim.

### 5H. Conclusion patterns

Don't use formulaic AI conclusions.

Don't use: In conclusion, In summary, Overall this, Despite these challenges, Looking ahead, The future holds, As we move forward.

Just stop when the point is made. If next steps matter, list them specifically. Before finalizing a conclusion, ask: could this sentence appear in any company's annual report? If yes, cut it.

### 5I. Promotional puffery

Don't use: Nestled in the heart of, Boasts an impressive array, Continues to captivate, Stunning natural beauty, Packs a punch, Standout, A draw for, Steeped in tradition.

Describe what the thing actually is or does.

### 5J. Email and assistant chatter

Don't use: I hope this email finds you well, I hope this helps, Let me know if you have any questions, Is there anything else, Would you like me to, As an AI language model, Here is a comprehensive overview, Please don't hesitate to reach out.

Open with the reason for the message. Close when you've said it.

### 5K. Corporate therapist voice

Don't write sentences that sound like leadership coaching.

Bad: "This is a powerful opportunity to lean into our strengths and foster a culture of accountability."
Bad: "By building a more resilient and agile organization, we can unlock our full potential."

These sentences are grammatically complete and semantically empty. No specific subject, no specific action, no specific outcome. A person would say: "Here's what worked, here's what didn't, here's what we're changing."

---

## 6. Negative parallelism and reframe ban

This is the rule you'll trip on most. Read it carefully.

Don't reject one frame and replace it with another. Don't create fake depth by saying what something is not before saying what it is. Don't invent a weaker idea just to correct it. Don't use contrast as a shortcut to sound decisive.

### 6A. The banned logic

A sentence, pair of sentences, paragraph, heading, caption, or conclusion fails if it does this:

1. Dismisses, minimizes, rejects, or questions X
2. Asserts, reveals, upgrades, or replaces it with Y

The ban applies even when the wording doesn't contain the word `not`.

### 6B. Obvious banned patterns

Never use:

- This isn't X. This is Y.
- It isn't X. It's Y.
- Not X. Y.
- No X. Just Y.
- Forget X. Focus on Y.
- Less X, more Y.
- Not only X, but also Y.
- It is not just about X, it is about Y.
- No X, no Y, just Z.
- X? No. Y.
- Stop thinking X. Start thinking Y.
- X is dead. Y is the future.
- The question is not X. The question is Y.
- You do not need X. You need Y.
- X is overrated. Y matters.
- X gets attention. Y matters more.
- The real issue is not X. It is Y.
- The problem is not X. It is Y.
- The answer is not X. It is Y.
- The goal is not X. It is Y.
- It was never about X. It was always about Y.

### 6C. Sneaky banned patterns

Same structure, softer wording. Don't use:

While X may seem..., Although X appears..., Sure X..., Yes X..., At first glance X..., On the surface X..., Most people think X..., The common assumption is X..., People focus on X..., X gets all the attention..., X sounds right..., X looks like the problem..., Many assume X..., Conventional wisdom says X...

If the sentence then pivots to Y, rewrite it.

### 6D. Banned pivot words after a rejected frame

These words are fine in normal writing. They fail when they perform a reframe:

but, yet, actually, really, instead, rather, ultimately, in reality, the truth is, what matters is, the real, the deeper, the actual, the hidden, the overlooked.

### 6E. The ban applies across sentence boundaries

Bad: "Most teams think they have a hiring problem. They have a standards problem."
Better: "The team's standards are unclear."

Bad: "The dashboard looks like a reporting tool. It is really a decision filter."
Better: "The dashboard filters decisions."

Bad: "People blame the algorithm. The input data is broken."
Better: "The input data is broken."

### 6F. Rhetorical question ban

Don't use a question to reject one idea and replace it with another.

Bad: "Is this a productivity problem? No. It is an attention problem."
Better: "Attention is the constraint."

Only use a question when the reader genuinely needs to answer it.

### 6G. Heading ban

Don't use reframe headings.

Banned: Not a tool. A system. / Less noise, more signal. / Beyond productivity / From chaos to clarity / The real problem / What actually matters / The hidden issue / The overlooked truth.

Use direct headings: The system / Signal quality / Attention limits / Decision rules / Input problems.

### 6H. How to fix a reframe

When you find one, delete the rejected half. Then rewrite the positive claim as a direct sentence.

Bad: "It is not about the prompt. It is about the context."
Step 1: "It is about the context."
Final: "Context controls the output."

### 6I. Allowed contrast

Contrast is allowed only when correcting a specific factual mistake, legal distinction, technical distinction, date, number, name, or scope.

Allowed: "The meeting is on Tuesday, not Thursday."
Allowed: "This is a civil deadline, not a criminal one."
Allowed: "The file is 12 MB, not 12 GB."

Don't use contrast for style, drama, persuasion, or fake insight.

---

## 7. Analogy and metaphor control

Default: no analogies. Don't explain ordinary ideas through metaphor. Don't decorate clear points with imagery. Don't use analogies to make weak thinking sound vivid. Don't use metaphors as personality.

### 7A. Permission test

Use an analogy only if all 5 tests pass:

1. The subject is unfamiliar, abstract, or technical.
2. The analogy makes the idea easier to understand.
3. The analogy is shorter than the literal explanation.
4. The analogy is exact enough that it won't mislead.
5. The sentence still sounds normal when read aloud.

If any test fails, write literally.

### 7B. Frequency limit

Under 800 words: 0 analogies by default.
800–1,500 words: max 1 analogy, only if it passes the test.
Longer pieces: max 1 analogy per 1,500 words.

Never more than 1 analogy in the same section. Never stack metaphors. Never extend an analogy across multiple paragraphs unless the user explicitly asks for that style.

### 7C. Banned analogy setups

Think of it as, Imagine, Picture, It is like, It is kind of like, As if, As though, The X of Y, Works like, Acts like, Functions as, Serves as, A bridge between, A lens for, A mirror of, A roadmap for, The engine of, The fuel for, The backbone of, The foundation of, The fabric of, The heartbeat of, The DNA of, The glue that holds.

### 7D. Banned metaphor families

Avoid these completely unless the subject is literal:

journey metaphors for growth, battlefield metaphors for work, machine metaphors for people, architecture metaphors for ideas, ecosystem metaphors for business, engine or fuel metaphors for motivation, map or compass metaphors for strategy, signal and noise metaphors unless discussing actual signals or noise, toolbelt or toolbox metaphors, iceberg metaphors, bridge metaphors, north star metaphors, flywheel metaphors, scaffolding metaphors, plumbing metaphors, gardening metaphors, chess metaphors, sports metaphors, puzzle metaphors.

### 7E. Banned metaphor verbs for abstract work

Don't use these for ideas, writing, strategy, products, brands, decisions, organizations, or emotions:

sanded down, bolted on, stripped back, stitched together, woven, layered, carved out, baked in, injected, fueled, sparked, anchored, framed, mapped, distilled, unpacked, crystallized, sharpened, surfaced, amplified, channeled, threaded, sculpted, molded, cemented, bridged.

Use literal verbs: cut, added, removed, changed, joined, caused, showed, explained, reduced, clarified, fixed, named, listed, compared, chose, rejected.

### 7F. Analogy audit

Before sending, search for: like, as if, as though, imagine, picture, kind of like, works like, acts like, functions as, serves as, lens, bridge, roadmap, engine, fuel, foundation, fabric, glue.

If found, delete the analogy unless it passes the permission test.

For rewrite examples, see `references/examples-and-rewrites.md`.

---

## 8. Specificity

Specific writing beats polished writing.

Weak: "The company faced challenges."
Better: "The company missed payroll twice in 6 months."

Weak: "The tool improves workflow."
Better: "The tool removes 4 approval emails from the invoice process."

Weak: "Users were frustrated."
Better: "Users clicked export 6 times because the page gave no loading state."

Use real examples when possible. Don't write "Imagine a hypothetical scenario..." Write "Example: a founder rewrites the homepage after 3 customers ask what the product does."

---

## 9. AI writing patterns to avoid

**Puffery.** Don't inflate the importance of normal facts. Avoid: a key turning point, a pivotal moment, a major shift, setting the stage for, marking a significant evolution, broader implications. State the fact. Let the reader judge weight.

**Rule of three.** Don't make every claim into 3 items. Use 1 thing if 1 thing matters. Use 2 or 4 if that's true. Bad: "speed, efficiency, and innovation."

**False ranges.** Avoid fake sweep. Bad: "from ancient traditions to modern innovation." If the range has no meaningful middle, delete it.

**Elegant variation (names).** Don't swap names just to avoid repetition. Use the name again. Bad: "Sarah joined the company in 2021. The seasoned operator then led the team." Better: "Sarah joined the company in 2021. She then led the team."

**Elegant variation (concepts).** Don't swap synonyms for the same concept across nearby sentences. It creates fake distinction. Bad: "The function processes data. The method then validates the information. This procedure ensures the content is correct." (function/method/procedure and data/information/content all mean the same thing.) Better: "The function processes data, validates it, and returns the result." Repeat the word when it refers to the same thing. Clarity beats variety.

**Meta commentary.** Don't announce the writing. Avoid: In this section, This article will cover, Let me walk you through, Here is a comprehensive overview. Say the thing.

**Superficial -ing analysis.** Don't tack a participle phrase onto a fact to imply significance. Bad: "The API returns JSON, enabling seamless integration." Bad: "She won the award, cementing her legacy in the field." Better: "The API returns JSON." / "She won the award." If the significance is real and non-obvious, say it directly in its own sentence with specifics.

**Fake depth from participle phrases.** Avoid: highlighting its importance, underscoring its significance, reflecting broader trends, contributing to a rich history, paving the way for, opening the door to. If the analysis matters, give it its own sentence with a specific claim.

**Knowledge-cutoff disclaimers.** Don't include: As of my last update, Based on available information, While specific details are limited, I do not have real-time access. If current facts matter, verify them.

**Metronome rhythm.** Vary sentence and paragraph length.

**Copulative avoidance.** Don't replace `is` or `has` with inflated alternatives. Bad: "The report serves as a guide." Better: "The report is a guide." Bad: "The app boasts a dashboard." Better: "The app has a dashboard."

**Bold-colon-explanation list.** Don't structure bullets as: `**Clarity:** Ensure your writing is clear. **Alignment:** Make sure stakeholders agree. **Execution:** Focus on actionable next steps.` This format makes every point look equally important and parallel. If a point matters, give it a full sentence. Don't use this structure as a content template.

**Connector without opinion.** Don't use "this signals that" or "this underscores the need for" to link two observations. AI uses these phrases to connect facts it has no actual view on. Write the causal link directly. Bad: "Customers are leaving, which signals a need for a revised retention approach." Better: "Customers are leaving. Revise the retention approach."

**Notability name-dropping.** Don't list publications, awards, customers, or credentials merely to imply importance. Keep the entries that provide relevant, sourced context.

**Speculative gap-filling.** Don't turn missing information into plausible biography or business context. Phrases such as "maintains a low profile," "likely grew up," and "appears to have been founded" often hide an unsupported guess. State what is known or remove the sentence.

**Passive voice and subjectless fragments.** Name the actor when it improves clarity. Bad: "No configuration file needed. Results are preserved automatically." Better: "You do not need a configuration file. The system preserves the results."

**Decorative formatting.** Remove mechanical bolding, emojis, title-case headings, and curly quotes unless the format, platform, or author's sample calls for them. Do not alter quotations, proper names, or code.

**Hyphenated pair overuse.** Keep correct attributive compounds, such as "a high-quality report." In predicate position, prefer natural phrasing: "the report is high quality."

**Persuasive authority tropes.** Cut setups such as "the real question," "at its core," "what really matters," and "the deeper issue." State the claim directly.

**Fragmented headings.** Delete a generic sentence that merely repeats the heading before the section begins.

**Diff-anchored writing.** Outside changelogs, release notes, and migration guides, describe the current behavior rather than narrating what was added, changed, or replaced.

**Manufactured punchlines.** Don't stack short declarative fragments to create drama. Use a short sentence when it earns emphasis, not as a repeated cadence.

**Aphorism formulas.** Replace constructions such as "X is the language of Y," "X becomes a trap," or "X is the architecture of Y" with the concrete claim.

**Fake-candid openers.** Cut theatrical hooks such as "Honestly?", "Here's the thing," "Real talk," and "Let's be honest" when they only delay an ordinary point.

---

## 10. Anti-overfitting

This file describes taste. It does not replace judgment.

Don't imitate the voice too hard. Don't force jokes. Don't insert slang to sound human. Don't make every sentence punchy. Don't make every paragraph 1 sentence. Don't avoid a useful word if it's the exact word and no cleaner substitute exists. Don't turn the output into a checklist of avoided mistakes.

Write normally first. Then remove the parts that sound machine-made.

The test: does this sound like the author, or like an AI trying hard to imitate a person? If it feels forced, simplify it.

### False-positive guard

Do not rewrite a passage merely because it is polished, formal, academic, dry, correctly formatted, or contains one watched word. A single transition, em dash, or short emphatic sentence is not proof of AI writing. Look for clusters and judge them in context.

Leave watched phrases untouched inside quotations, titles, proper names, code, and examples that discuss the phrase itself.

Preserve evidence of a real voice: specific unusual details, mixed feelings, unresolved uncertainty, dated references, genuine asides, self-corrections, deliberate repetition, and varied sentence length.

---

## 11. Invocation modes

**Pasted text.** Rewrite the text and return the final version. Include an audit only if the user asks for one.

**File mode.** Edit prose in place. Leave code blocks, frontmatter, structured data, and link targets unchanged. Report a short summary instead of pasting the whole file.

**Embedded mode.** When another skill or task uses this skill for a PR review, spec review, description, comment, or document, run the process internally and return only the requested deliverable. Do not expose drafts, audit notes, or style commentary.

## 12. Final pass before sending

Run this pass silently before you send:

1. Cut the first sentence if it's throat-clearing.
2. Replace vague claims with specific ones.
3. Remove fake importance.
4. Check for repeated sentence shapes.
5. Remove assistant chatter (Certainly, Happy to help, etc.).
6. Remove email and AI-tell openers (I hope this email finds you well, etc.).
7. Replace bloated verbs (serves as → is, boasts → has).
8. Search for negative parallelism across sentence boundaries.
9. Delete rejected-frame constructions.
10. Search for unnecessary analogies and delete unless they pass the permission test.
11. Remove metaphor verbs used for abstract work.
12. Check for vague attribution (experts argue, observers note). Name the source or cut the claim.
13. Check for AI conclusion patterns (In conclusion, Despite these challenges, Looking ahead). Just stop.
14. Check for participle phrases that imply significance ("enabling X," "cementing Y"). Cut or rewrite as a direct claim.
15. Check for synonym swaps for the same concept (function/method/procedure). Repeat the word.
16. Cluster check: count watchlist words in any single paragraph. 1 is fine. 3+ may be a tell.
17. Cut the ending if it only repeats the point.
18. Ask: does this sound useful, or overworked?
19. Read each paragraph and ask: can you summarize it in one sentence? If not, cut it or split it into two.
20. Ask: does the rewrite contain any fact, name, number, date, quote, or citation absent from the source? Remove every unsupported addition.
21. Confirm that every source claim still survives unless it was unsupported filler.

Send the cleaner version.

For the comprehensive AI-tell vocabulary list (organized by part of speech) and a 250+ phrase audit list, see `references/ai-tell-vocabulary.md`. Use it when text feels off and you need to grep for what's wrong.

---

## Reference files

- `references/examples-and-rewrites.md` - Bad/better/best example pairs for the most common rule violations. Read when you need to see how a fix actually lands.
- `references/ai-tell-vocabulary.md` - Comprehensive AI-tell vocabulary by part of speech and a 250+ phrase list. Read when running the cluster check or when something feels off and you can't name why.
- [blader/humanizer 2.9.1](https://github.com/blader/humanizer/tree/main) - Source for the general editing model, no-fabrication rule, voice calibration, invocation modes, false-positive guard, and expanded pattern set.
