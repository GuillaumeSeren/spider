spider
======
Explore a web application and test linked ressources.

## Why ?
Test a webapp, hunt for 404.

## Design
The script is split arround 3 modules:
* spider: User interface, can instanciate other modules.
* web: Return linked ressources on a given URL (also img, css, js).
* prober: Test a URL and return HTTP code.

## Beta / Proof
This script is still in beta.

## Features
Here is a list of needed features.

STATUS | DESCRIPTION
-------|------------
`DONE` | Return a list of linked ressources of 1 page.
`DONE` | Return the HTTP status of a ressources (link).
`DONE` | Return the time of the prober call on a ressource.
`TODO` | Discover recursively all ressources, to slow actually.
`TODO` | Generate a dependency graph to represent the webapp.
`TODO` | Add a DB to store the graph, and request it.

## Participate !
If you find it useful, and would like to add your tips and tricks in it,
feel free to fork this project and fill a __Pull Request__.

## Licence
The project is GPLv3.
