---
windsurf: guide
title: Tailwind Refactor Guide
tags: [style, tailwind, design-system]
roles: [developer, designer]
---

# Tailwind Refactor Guide – Athlete Ace

> **Goal:** Replace “utility‑soup everywhere” with a small, well‑documented Tailwind design system that keeps templates short, lets you experiment quickly, and plays nicely with Rails 8 & Turbo.

---

## 1 · File layout

```text
app/assets/tailwind/
├── application.tailwind.css      # Loads Tailwind base + all partials
├── components/
│   ├── buttons.css               # @layer components – .btn, .btn--*
│   ├── cards.css                 # …other UI blocks
│   └── forms.css
└── utilities/
    ├── debug.css                 # @layer utilities – helper classes
    └── themes.css                # CSS vars, dark‑mode tweaks
└── players.css                   # @layer styles for entities
└── teams.css
└── strength.css                  # @layer styles for pages and interfaces
└── stats.css
└── pagination.css
└── 
```

* **application.tailwind.css** should contain **nothing** but imports:

  ```css
  @tailwind base;
  @tailwind components;
  @tailwind utilities;

  /* 🚚 pull in your partials */
  @import "components/buttons.css";
  @import "components/cards.css";
  @import "components/forms.css";
  @import "utilities/debug.css";
  @import "utilities/themes.css";
  ```
* Put every `@apply` rule **inside `@layer components` or `@layer utilities`** so purge/treeshake keeps working.

---

## 2 · Writing component CSS

```css
/* components/buttons.css */
@layer components {
  .btn {
    @apply inline-flex items-center gap-1 font-semibold leading-tight px-3 py-1.5 rounded-lg transition hover:opacity-80; /* basic anatomy */
  }

  .btn--primary   { @apply bg-blue-600 text-white; }
  .btn--ghost     { @apply text-blue-600 bg-transparent border border-blue-600; }
  .btn--disabled  { @apply opacity-40 cursor-not-allowed; }
}
```

*Document choices inline* (right‑side comments) – future‑you will thank you.

---

## 3 · Using classes in views

```erb
<%= link_to "Save", "#", class: "btn btn--primary" %>
```

*Templates stay readable; 120‑column rule survives.*

Occasional one‑off utilities are fine (< 5 % of lines) while you’re iterating.

---

## 4 · Helpers & Stimulus

| Layer                    | Allowed to know Tailwind?                                                                      |
| ------------------------ | ---------------------------------------------------------------------------------------------- |
| **View helpers**         | **No.** Return semantic classes (`"badge badge--danger"`).                                     |
| **Stimulus controllers** | Mostly **no** – toggle state classes (`is-active`, `hidden`) or data‑attrs, not raw utilities. |

---

## 5 · Editor & CI hygiene

* **Prettier** + `prettier-plugin-tailwindcss` keeps any leftover utility strings sorted.
* **Stylelint** (`stylelint-config-standard`, `stylelint-order`) enforces order inside CSS files.
* **Rubocop ERB** / **erb-lint** checks that class lists aren’t absurdly long.

---

## 6 · Rails config tweaks

```ruby
# config/environments/development.rb
config.assets.css_compressor = nil                     # keep comments when live‑reloading
config.action_view.preload_links_header = false        # fixes Safari module cache
```

---

## 7 · Incremental migration plan

| Sprint | Task                                                                                                        | Outcome                     |
| ------ | ----------------------------------------------------------------------------------------------------------- | --------------------------- |
| 1      | Create folder structure, move “btn” utilities into `components/buttons.css`, refactor high‑traffic buttons. | Immediate readability bump. |
| 2      | Sweep view helpers & Stimulus – replace utility blobs with semantic classes.                                | Logic/style separation.     |
| 3      | Convert layout partials (nav, footer, modals).                                                              | Unified look.               |
| 4      | Audit templates: any line >120 chars? extract class.                                                        | Stable codebase.            |
| 5      | Delete old utility‑only CSS files; document pattern in README.                                              | 💅 Done.                    |

### Progress Update

✅ **Completed: Index Pages Refactoring**

We've successfully refactored the `index_pages.css` to use Tailwind's `@apply` directive with semantic classes:

1. Created `app/assets/tailwind/components/index_pages.css` with semantic classes
2. Used `@apply` to connect them to Tailwind utility classes
3. Imported the component file in `app/assets/tailwind/components.css`
4. Removed the direct import from `app/assets/stylesheets/application.css`

This approach maintains the same visual appearance while making the CSS more maintainable and consistent with our Tailwind architecture.

---

## 8 · Advanced patterns

* **Dark mode** – override inside the same component file:

  ```css
  @layer components {
    .dark .btn--primary { @apply bg-blue-400; }
  }
  ```
* **Variants (`hover`, `disabled`, `lg:`)** – inline or via Tailwind’s `variant` plugins.
* **design‑time hacks** – keep them in `utilities/debug.css`; delete before PR merge.

---

### TL;DR

1. Multiple Tailwind partials under `components/` & `utilities/`.
2. Semantic classes in ERB; `@apply` lives in CSS.
3. Helpers/Stimulus logic‑only.
4. Lint & auto‑format.
5. Migrate page‑by‑page – no big bang.

Take this file as **the single source of truth** while refactoring Athlete Ace’s front‑end.

Note that at this point, none of the existing styles are considered mission-critical. We will plan to preserve them, but we will not be held to them.