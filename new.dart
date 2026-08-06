DecoratedBox
(
decoration: BoxDecoration(...),
child: Material( // Ajoute ceci
type: MaterialType.transparency,
child: ListTile(
onTap: () {},
...
)
,
)
,
)
    