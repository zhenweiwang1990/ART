import art
from art_e.rollout import rollout
from art_e.data.query_iterators import load_synthetic_queries
import polars as pl


async def benchmark_model(
    model: art.Model, limit: int = 100, swallow_exceptions: bool = True
) -> pl.DataFrame:
    val_scenarios = load_synthetic_queries(split="test", limit=limit)
    # Run sequentially for clearer, easier-to-analyze logs
    val_trajectories = []
    for scenario in val_scenarios:
        try:
            traj = await rollout(model, scenario)
            val_trajectories.append(traj)
        except BaseException as e:
            if swallow_exceptions:
                val_trajectories.append(e)
            else:
                raise

    valid_trajectories = [t for t in val_trajectories if isinstance(t, art.Trajectory)]

    if model._api is not None:
        await model.log(valid_trajectories)

    metrics = pl.DataFrame(
        [{**t.metrics, "reward": t.reward} for t in valid_trajectories]
    )

    avg_metrics = metrics.select(
        [pl.mean(c).alias(c) for c in metrics.columns]
    ).with_columns(pl.lit(len(valid_trajectories)).alias("n_trajectories"))

    return avg_metrics
