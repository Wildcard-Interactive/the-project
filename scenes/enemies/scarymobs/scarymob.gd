class_name Scarymob
extends CharacterBody2D
## Placeholder body shared by the scarymobs creature set.
##
## Deliberately has no behaviour. These scenes exist so levels have something
## instantiable with the right sprite and a collision footprint; drone.gd is
## the reference for how patrol logic gets bolted on later. Nothing here should
## be read as the final AI shape.
##
## One script backs all five scenes because the stubs are identical -- split it
## per-creature once they actually behave differently.

## Which creature this is. Set per scene; useful for debug output and for
## whatever spawn table eventually references these.
@export var display_name: String = ""
