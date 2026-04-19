# Components

## What is a component?

In programming, and in this codebase, a component is a smaller object owned by a larger object.

Each component is generally responsible for one specialized task. Some components have their own scenes, while others are just script types that can be added from the editor as child nodes by typing their `class_name`.

## Why use components?

There are several reasons to use components:

- Components help each script follow the Single Responsibility Principle, preventing massive "god scripts."
- Components are reusable, modular, and typically atomic. This means an entity should only need to attach the components it actually uses.
- Components improve testing because they are modular and isolated. You can even make temporary test components when needed.
- Components allow for low coupling in systems programming. Because of Godot's signals, components can often take a "fire and forget" approach to their responsibility. They do not need to track what every other node is doing; they only need to handle their own task.
- Components are easy to extend for custom functionality. Custom behavior can also be created by combining different components and signal connections.
- Components allow entity root scripts to act more like managers instead of ballooning into fragile, unmaintainable messes. This helps enforce clean software organization in code while still preserving the usual clean Godot scene flow.
