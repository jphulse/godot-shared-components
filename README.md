# Godot Shared Components

This repository is a collection of shared components and data structures for use across multiple Godot projects, developed on and works on Godot 4.6, minimum version Godot 4.5.

**NOTE** This library is currently in early development so all classes are subject to change, since it is on git you can restore an older version if needed for your codebase


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

### Project owner or initial setup
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

### Project teammate setup after the owner pushes the submodule

After the project owner adds the submodule and pushes the outer project repository, teammates need to initialize and download the submodule locally.

If cloning the project for the first time, use:
```bash
git clone --recurse-submodules <project-repository-url>
```
If the project was already cloned before the submodule was added, run this from the root of the outer Godot project:
```bash
git pull
git submodule update --init --recursive
```
This downloads the shared components repository into:
```text
addons/jeremy_components
```
After the submodule is downloaded, open the Godot project in the editor and enable the addon from:
```text
Project > Project Settings > Plugins
```
Enable the plugin by switching it to **On**.

If the submodule folder exists but appears empty, or Godot cannot find the addon, run the update command again from the project root:
```bash
git submodule update --init --recursive
```
If the project owner, or another team member later updates the shared components version used by the project, teammates should pull the outer project and update the submodule again:
```bash
 git pull
 git submodule update --init --recursive
```
The important detail is that teammates should not manually clone the shared components repository into `addons/jeremy_components`. Git should manage that folder as a submodule.

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
