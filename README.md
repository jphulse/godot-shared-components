# Godot-Shared-Components
This repository is a collection of shared components and datastructures for use across multiple godot projects

## File structure
* components
	* Contains reusable components for composition system, (i.e. healthComponent, HitboxComponent, etc)
* state_machine
	* Contains a reusable state machine, nested state machine, and extendable state class
* util_data_structures
	* Contains datastructures for project use, including an Adjacency List anmd Linked List
* util_data_types
	* Basic data type objects, will mostly extend resource or refcounted for use inside and outside of addon
	* When adding game specific objects to these classes extend the existing class and keep it local to your game
