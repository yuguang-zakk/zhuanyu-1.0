# Zhuanyu Recipe Blocks

A SwiftUI iOS app for building modern, visual, block-based recipes. Each recipe is stored locally as a plain `.md` file and rendered into editable blocks (hero, ingredients, steps, notes) with time + heat metadata.

## What you can do
- Create and edit recipes offline
- Compose recipes from visual blocks
- Attach timers and heat levels to steps
- Pick icons for steps and ingredients
- Save everything as plain Markdown files

## How it works
- Source of truth: `.md` files saved in the app Documents folder under `Recipes/`
- Index: SwiftData `RecipeRecord` keeps a lightweight list for fast browsing
- Rendering: Markdown is parsed into `RecipeBlock` models, then rendered as SwiftUI cards

## Markdown format
The app writes a very simple block syntax you can edit by hand if you want.

```markdown
# Weeknight Stir-Fry

[hero]
image: hero
servings: 2
time: 20m
nutrition: 520 kcal

[ingredients]
- name=Noodles | amount=200g | icon=leaf.fill
- name=Chili oil | amount=1 tbsp | icon=flame.fill

[step]
title: Boil noodles
time: 8m
heat: high
icon: timer
text: Boil noodles until al dente.

[note]
text: Finish with scallions and sesame seeds.
```

## Project layout
- `zhuanyu/Models` Core models (`RecipeBlock`, `RecipeRecord`, `RecipeDocument`)
- `zhuanyu/Parsing` Markdown codec
- `zhuanyu/Storage` File store + sync
- `zhuanyu/Views` SwiftUI screens and block editors

## Run
1. Open `zhuanyu/zhuanyu.xcodeproj` in Xcode.
2. Build and run on an iPhone simulator or device.

## Next steps
- Add a real icon/animation asset library
- Add drag-to-reorder blocks
- Add rich step types (timers, heat graphs, utensils)
- Add image/video attachments per step
