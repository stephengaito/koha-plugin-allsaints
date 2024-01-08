# Books checked out plugin for Koha

This plugin lists the pupils and the books which they have currently
checked out.

Any books which are overdue are listed with the due date in RED.

This report also records when a pupil checked out the book and how many
weeks they have had the book checked out.

This report is typically run at each half term.

## Creating your own Koha Plugin Zip (KPZ) file

To create your own Koha Plugin Zip file, clone this repository and then
inside the cloned repository, in a Linux command line terminal, type:

```
  ./scripts/updateBooksCheckedOutKPZ

```

The resulting KPZ file will be found in the `kpz` directory.

## Installation

This plugin requires the Perl libraries:

- [Text::CSV::Slurp](https://metacpan.org/pod/Text::CSV::Slurp)

- [PDF::API2](https://metacpan.org/pod/PDF::API2)

To install these plugins, you can follow the `Install Instructions` link
in the web pages listed above.

You *must* install these Perl libraries *before* uploading and installing
this plugin in Koha.

## License

The code implementing this plugin was originally taken from the
[ByWaterSolutions](https://github.com/bywatersolutions)
[koha-plugin-patron-last-activity](https://github.com/bywatersolutions/koha-plugin-patron-last-activity)
plugin on November 1st 2023 (commit 5feba1a on Apr 8, 2022).

It has been altered and re-released for its new purpose under the original
[GNU 3.0 License](http://www.gnu.org/licenses/) see the LICENSE file in
this repository for details.

The code in this repository is now:

---
    Copyright (C) 2023 Stephen Gaito (on behalf of AllSaints CofE School
    Leek Wootton, Warwickshire, UK)

    (orignal) Copyright (C) 2022 ByWaterSolutions

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
---
