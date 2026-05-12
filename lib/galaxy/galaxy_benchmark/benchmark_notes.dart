part of '../galaxy_benchmark_page.dart';


// Footnotes explaining compare mode and FFI batching.
//
// Part of the galaxy benchmark library; see `galaxy_benchmark_page.dart`.

class _BenchmarkNotesPanel extends StatelessWidget {
  const _BenchmarkNotesPanel();

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Benchmark notes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          const _NoteRow(
            icon: Icons.balance,
            text:
                'Compare mode reseeds all backends together so they start from the same galaxy field.',
          ),
          const _NoteRow(
            icon: Icons.palette,
            text:
                'Visual selector changes only the canvas layer; the Dart, C, and Rust compute paths stay comparable.',
          ),
          const _NoteRow(
            icon: Icons.call_merge,
            text:
                'Each FFI path does all selected substeps inside one native call per frame.',
          ),
          const _NoteRow(
            icon: Icons.storage,
            text:
                'Compute can use a larger native buffer than the number of particles drawn on screen.',
          ),
          const _NoteRow(
            icon: Icons.warning_amber,
            text:
                'If Dart wins here, the correct lesson is: keep simple logic in Dart.',
          ),
          const _NoteRow(
            icon: Icons.inventory_2,
            text:
                'Use FFI when native code gives you a capability: SDK, audited library, hardware API, or existing engine.',
          ),
        ],
      ),
    );
  }
}
