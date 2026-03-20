import 'package:flutter/material.dart';

class SimulationScene3 extends StatelessWidget {
	const SimulationScene3({super.key});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Kitchen Fire Simulation'),
			),
			body: const Center(
				child: Padding(
					padding: EdgeInsets.all(24),
					child: Text(
						'Kitchen Fire simulation scene is not available yet.',
						textAlign: TextAlign.center,
					),
				),
			),
		);
	}
}
