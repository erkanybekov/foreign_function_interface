use std::slice;

const BANK_OK: i32 = 0;
const BANK_ERR_NULL_POINTER: i32 = -1;
const BANK_ERR_INVALID_ARGUMENT: i32 = -2;
const BANK_GALAXY_PARTICLE_STRIDE: usize = 4;
const BANK_RUST_BACKEND_VERSION: i32 = 1;

#[inline]
fn fractional(value: f32) -> f32 {
    value - value.floor()
}

#[inline]
fn respawn_galaxy_particle(
    particle: &mut [f32],
    index: usize,
    respawn_radius: f32,
    center_pull: f32,
) {
    let seed = index as f32 + 1.0;
    let x_seed = fractional(seed * 0.61803398875);
    let y_seed = fractional(seed * 0.75487766625);
    let vx_seed = fractional(seed * 0.41421356237);
    let vy_seed = fractional(seed * 0.56984029099);

    particle[0] = ((x_seed * 2.0) - 1.0) * respawn_radius;
    particle[1] = ((y_seed * 2.0) - 1.0) * respawn_radius;
    particle[2] = 0.010 + (vx_seed - 0.5) * 0.030 + center_pull * 0.010;
    particle[3] = (vy_seed - 0.5) * 0.022;
}

fn update_galaxy_particles_once(
    particles: &mut [f32],
    particle_count: usize,
    dt_seconds: f32,
    center_pull: f32,
    swirl: f32,
    damping: f32,
    escape_radius: f32,
    respawn_radius: f32,
) {
    let safe_dt = dt_seconds.min(0.05);

    for (index, particle) in particles
        .chunks_exact_mut(BANK_GALAXY_PARTICLE_STRIDE)
        .take(particle_count)
        .enumerate()
    {
        let mut x = particle[0];
        let mut y = particle[1];
        let mut vx = particle[2];
        let mut vy = particle[3];

        if x.abs() > escape_radius || y.abs() > escape_radius {
            respawn_galaxy_particle(particle, index, respawn_radius, center_pull);
            continue;
        }

        let phase = (index as f32 + 1.0) * 0.031;
        let turbulence_x = ((y * 3.7) + phase).sin();
        let turbulence_y = ((x * 2.9) - phase).cos();
        let ax = (center_pull * 0.018) + (turbulence_x * swirl * 0.010);
        let ay = turbulence_y * swirl * 0.008;

        vx = (vx * damping) + (ax * safe_dt);
        vy = (vy * damping) + (ay * safe_dt);
        x += vx * safe_dt;
        y += vy * safe_dt;

        particle[0] = x;
        particle[1] = y;
        particle[2] = vx;
        particle[3] = vy;
    }
}

#[no_mangle]
pub extern "C" fn bank_rust_backend_version() -> i32 {
    BANK_RUST_BACKEND_VERSION
}

#[no_mangle]
pub unsafe extern "C" fn bank_update_galaxy_particles_rust(
    particles: *mut f32,
    particle_count: i32,
    dt_seconds: f32,
    center_pull: f32,
    swirl: f32,
    damping: f32,
    escape_radius: f32,
    respawn_radius: f32,
) -> i32 {
    unsafe {
        bank_update_galaxy_particles_rust_batched(
            particles,
            particle_count,
            dt_seconds,
            center_pull,
            swirl,
            damping,
            escape_radius,
            respawn_radius,
            1,
        )
    }
}

#[no_mangle]
pub unsafe extern "C" fn bank_update_galaxy_particles_rust_batched(
    particles: *mut f32,
    particle_count: i32,
    dt_seconds: f32,
    center_pull: f32,
    swirl: f32,
    damping: f32,
    escape_radius: f32,
    respawn_radius: f32,
    substeps: i32,
) -> i32 {
    if particles.is_null() {
        return BANK_ERR_NULL_POINTER;
    }

    if particle_count < 0
        || substeps <= 0
        || dt_seconds <= 0.0
        || center_pull <= 0.0
        || swirl <= 0.0
        || damping <= 0.0
        || escape_radius <= 0.0
        || respawn_radius <= 0.0
    {
        return BANK_ERR_INVALID_ARGUMENT;
    }

    let particle_count = particle_count as usize;
    let Some(float_count) = particle_count.checked_mul(BANK_GALAXY_PARTICLE_STRIDE) else {
        return BANK_ERR_INVALID_ARGUMENT;
    };
    let buffer = unsafe { slice::from_raw_parts_mut(particles, float_count) };

    for _ in 0..substeps {
        update_galaxy_particles_once(
            buffer,
            particle_count,
            dt_seconds,
            center_pull,
            swirl,
            damping,
            escape_radius,
            respawn_radius,
        );
    }

    BANK_OK
}
