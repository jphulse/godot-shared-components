# Godot Shared Components

This repository is a collection of shared components and data structures for use across multiple Godot projects.

## Addon Path

This repository is intended to be added to Godot projects at:

```text
res://addons/jeremy_components
```

Godot recognizes the addon through the `plugin.cfg` file at the root of this repository.

## File Structure

* `components`
	* Contains reusable components for a composition-based system, such as `HealthComponent`, `HitboxComponent`, etc.

* `state_machine`
	* Contains a reusable state machine, nested state machine, and extendable state class.

* `util_data_structures`
	* Contains reusable data structures for project use, including an adjacency list and linked list.

* `util_data_types`
	* Contains basic data type objects. These will mostly extend `Resource` or `RefCounted` for use inside and outside of the addon.
	* When adding game-specific objects, extend the existing shared class and keep the game-specific subclass local to your game project.

## Setup

Copy the provided `add-godot-components` script to your `bin` directory. Optionally, add that directory to your `PATH` so the script can be run from anywhere.

Before using the script, change the variables at the top of the file to match your desired repository URL and addon path.  All commands below will be done assuming the addon path is "addons/jeremy_components"

After creating a new Godot project, run the script from the root directory of the project:

```bash
add-godot-components
```

This will configure the shared components repository as a Git submodule.

After that, open the Godot project in the editor and enable the addon from:

```text
Project > Project Settings > Plugins
```

Enable the plugin by switching it to **On**.

Once the addon is configured, add the submodule reference to the outer Git repository:

```bash
git add .gitmodules addons/jeremy_components
git commit -m "Add shared Godot components submodule"
git push
```

## Modifying the Submodule

Git treats the submodule like a normal repository. You can enter the submodule directory and use normal Git commands:

```bash
cd addons/jeremy_components
git add .
git commit -m "Update shared components"
git push
```

You can also pull updates from the shared repository:

```bash
cd addons/jeremy_components
git pull
```

After any incoming or outgoing commits in the submodule, the outer repository must also save the updated submodule commit reference.

From the outer project root:

```bash
git add addons/jeremy_components
git commit -m "Update shared components submodule"
git push
```

The outer repository does not store the full contents of the submodule. It stores a reference to a specific commit in the shared components repository.
