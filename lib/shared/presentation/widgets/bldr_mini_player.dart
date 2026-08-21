import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:bldr_fitness/features/club/presentation/bldr_club/club_active_workout_screen.dart';
import 'package:bldr_fitness/features/workouts/presentation/workouts_screen/active_workout_screen.dart';
import 'package:bldr_fitness/shared/providers/workout_session_provider.dart';

class BldrMiniPlayer extends StatelessWidget {
  const BldrMiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutSessionProvider>(
      builder: (context, provider, _) {
        if (!provider.isVisible) return const SizedBox.shrink();

        final workout = provider.pausedWorkout!;

        return Positioned(
          left: 16,
          right: 16,
          bottom: 140,
          child: GestureDetector(
            onTap: () => _resumeWorkout(context, provider),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0D0D0D),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      color: Color(0xFFD4AF37),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          workout.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pausado · toque para continuar',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFB8901E), Color(0xFFE0B830)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF0A0A0A),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _resumeWorkout(BuildContext context, WorkoutSessionProvider provider) {
    final workout = provider.pausedWorkout;
    if (workout == null) return;
    provider.hide();

    final route = workout.source == 'club'
        ? MaterialPageRoute(
            builder: (_) => ClubActiveWorkoutScreen(
              workoutId: workout.id,
              workoutName: workout.name,
            ),
          )
        : MaterialPageRoute(
            builder: (_) => ActiveWorkoutScreen(
              workoutId: workout.id,
              workoutName: workout.name,
            ),
          );

    Navigator.of(context).push(route).then((_) => provider.show());
  }
}
