# Cupward

**Better coffee, one cup at a time.**

Cupward is an AI-powered coffee brewing companion that helps coffee enthusiasts understand, refine, and improve their brewing technique through data-driven insights and personalized recommendations.

By combining real-time brewing measurements, subjective tasting feedback, and artificial intelligence, Cupward transforms each cup of coffee into an opportunity to learn. Rather than simply following a recipe, users can understand how their brewing decisions influence the resulting cup and make informed adjustments to achieve their preferred flavor.

## The Idea

Brewing great coffee is an iterative process. Variables such as grind size, water temperature, coffee-to-water ratio, brewing technique, and extraction time all influence the final result. Even small adjustments can produce noticeably different flavors.

The challenge is understanding which adjustments to make.

Traditional brewing tools help users measure and reproduce their technique, but measurements alone cannot explain whether a cup tastes good or how it could be improved. Cupward bridges this gap by connecting objective brewing data with the subjective experience of drinking coffee.

The fundamental idea is simple:

**Brew. Taste. Learn. Repeat.**

Each brewing session contributes to a growing understanding of the user's preferences and the relationship between brewing technique and flavor.

## How It Works

Cupward brings together three sources of information:

1. **Brewing measurements:** A Bluetooth-connected coffee scale provides real-time weight, flow rate, and timing information, allowing Cupward to capture how a cup was brewed.
2. **Tasting feedback:** Users describe the resulting coffee, including its flavor characteristics, perceived quality, and aspects they would like to improve.
3. **AI-powered analysis:** Artificial intelligence evaluates the brewing measurements alongside tasting feedback to identify patterns, explain potential relationships, and recommend adjustments for subsequent brews.

This creates a feedback loop in which each brewing session informs the next. Over time, Cupward helps users move beyond trial and error toward a more deliberate and repeatable brewing process.

## Guiding Principles

**The coffee comes first.** Technology should enhance the brewing experience without distracting from the enjoyment and ritual of making coffee.

**Measurements provide context, not judgment.** Brewing data describes what happened, but the user's experience determines whether the result was successful.

**Personal preference matters.** There is no universally perfect cup of coffee. Cupward should help users discover and consistently reproduce the coffee they enjoy.

**Recommendations should be understandable.** AI should do more than prescribe adjustments. Whenever possible, it should explain why a change might improve the result, helping users develop their own understanding of coffee brewing.

**Keep the experience approachable.** Users should not need to understand extraction theory, flow dynamics, or machine learning to benefit from Cupward. Complexity belongs behind an intuitive experience.

## Technology

Cupward combines a cross-platform Flutter application, Bluetooth-connected brewing hardware, and Firebase cloud infrastructure.

- **Flutter and Dart** provide the application experience.
- **BOOKOO Themis Ultra** provides real-time brewing measurements through Bluetooth Low Energy (BLE).
- **Firebase** provides cloud infrastructure and AI integration.
- **Hybrid AI** supports the interpretation of brewing data and generation of personalized recommendations.

The repository brings together the application, Firebase infrastructure, Flutter hardware integration, documentation, and supporting resources.

## Philosophy

Cupward is not intended to replace the craft of making coffee with an algorithm. Brewing coffee is a sensory, personal experience, and no collection of measurements can fully capture the qualities that make a cup enjoyable.

Instead, Cupward uses technology to make the relationship between technique and taste easier to understand.

The goal is not to brew a mathematically perfect cup of coffee. It is to help each person brew a cup they enjoy more than the last one.