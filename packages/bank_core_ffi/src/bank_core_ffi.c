#include "bank_core_ffi.h"

#include <ctype.h>
#include <math.h>

static float bank_fractional(float value) { return value - floorf(value); }

static void bank_respawn_galaxy_particle(
    float* particle,
    int32_t index,
    float respawn_radius,
    float center_pull) {
  const float seed = (float)index + 1.0f;
  const float x_seed = bank_fractional(seed * 0.61803398875f);
  const float y_seed = bank_fractional(seed * 0.75487766625f);
  const float vx_seed = bank_fractional(seed * 0.41421356237f);
  const float vy_seed = bank_fractional(seed * 0.56984029099f);

  particle[0] = ((x_seed * 2.0f) - 1.0f) * respawn_radius;
  particle[1] = ((y_seed * 2.0f) - 1.0f) * respawn_radius;
  particle[2] = 0.010f + (vx_seed - 0.5f) * 0.030f + center_pull * 0.010f;
  particle[3] = (vy_seed - 0.5f) * 0.022f;
}

static void bank_update_galaxy_particles_once(
    float* particles,
    int32_t particle_count,
    float dt_seconds,
    float center_pull,
    float swirl,
    float damping,
    float escape_radius,
    float respawn_radius) {
  const float safe_dt = fminf(dt_seconds, 0.05f);

  for (int32_t index = 0; index < particle_count; index++) {
    float* particle = particles + (index * BANK_GALAXY_PARTICLE_STRIDE);
    float x = particle[0];
    float y = particle[1];
    float vx = particle[2];
    float vy = particle[3];

    if (fabsf(x) > escape_radius || fabsf(y) > escape_radius) {
      bank_respawn_galaxy_particle(particle, index, respawn_radius, center_pull);
      continue;
    }

    const float phase = ((float)index + 1.0f) * 0.031f;
    const float turbulence_x = sinf((y * 3.7f) + phase);
    const float turbulence_y = cosf((x * 2.9f) - phase);
    const float ax = (center_pull * 0.018f) + (turbulence_x * swirl * 0.010f);
    const float ay = turbulence_y * swirl * 0.008f;

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

FFI_PLUGIN_EXPORT int32_t bank_add(int32_t a, int32_t b) { return a + b; }

FFI_PLUGIN_EXPORT int32_t bank_validate_pan(const char* pan) {
  if (pan == 0) {
    return BANK_ERR_NULL_POINTER;
  }

  int digits[19];
  int digit_count = 0;

  for (const char* cursor = pan; *cursor != '\0'; cursor++) {
    const unsigned char value = (unsigned char)*cursor;
    if (isdigit(value)) {
      if (digit_count >= 19) {
        return 0;
      }
      digits[digit_count++] = value - '0';
      continue;
    }

    if (value == ' ' || value == '-') {
      continue;
    }

    return 0;
  }

  if (digit_count < 12) {
    return 0;
  }

  int checksum = 0;
  int double_digit = 0;
  for (int index = digit_count - 1; index >= 0; index--) {
    int digit = digits[index];
    if (double_digit) {
      digit *= 2;
      if (digit > 9) {
        digit -= 9;
      }
    }
    checksum += digit;
    double_digit = !double_digit;
  }

  return (checksum % 10) == 0 ? 1 : 0;
}

FFI_PLUGIN_EXPORT int32_t bank_validate_iban(const char* iban) {
  if (iban == 0) {
    return BANK_ERR_NULL_POINTER;
  }

  char normalized[35];
  int length = 0;

  for (const char* cursor = iban; *cursor != '\0'; cursor++) {
    unsigned char value = (unsigned char)*cursor;
    if (value == ' ') {
      continue;
    }

    if (value >= 'a' && value <= 'z') {
      value = (unsigned char)(value - 'a' + 'A');
    }

    if (!isalnum(value)) {
      return 0;
    }

    if (length >= 34) {
      return 0;
    }

    normalized[length++] = (char)value;
  }

  if (length < 15) {
    return 0;
  }

  if (!isupper((unsigned char)normalized[0]) ||
      !isupper((unsigned char)normalized[1]) ||
      !isdigit((unsigned char)normalized[2]) ||
      !isdigit((unsigned char)normalized[3])) {
    return 0;
  }

  int mod = 0;
  for (int offset = 4; offset < length + 4; offset++) {
    const unsigned char value = (unsigned char)normalized[offset % length];
    if (isdigit(value)) {
      mod = (mod * 10 + (value - '0')) % 97;
      continue;
    }

    if (isupper(value)) {
      const int expanded = value - 'A' + 10;
      mod = (mod * 10 + (expanded / 10)) % 97;
      mod = (mod * 10 + (expanded % 10)) % 97;
      continue;
    }

    return 0;
  }

  return mod == 1 ? 1 : 0;
}

FFI_PLUGIN_EXPORT int32_t bank_score_transaction(
    const BankTransactionRiskInput* input,
    BankRiskScore* output) {
  if (input == 0 || output == 0) {
    return BANK_ERR_NULL_POINTER;
  }

  if (input->amount_cents < 0 ||
      input->account_age_days < 0 ||
      input->failed_attempts_24h < 0) {
    return BANK_ERR_INVALID_ARGUMENT;
  }

  int32_t score = 0;
  int32_t flags = 0;

  if (input->amount_cents >= 2000000) {
    score += 35;
    flags |= BANK_RISK_FLAG_HIGH_AMOUNT;
  } else if (input->amount_cents >= 500000) {
    score += 20;
    flags |= BANK_RISK_FLAG_HIGH_AMOUNT;
  } else if (input->amount_cents >= 100000) {
    score += 10;
  }

  if (input->account_age_days < 30) {
    score += 25;
    flags |= BANK_RISK_FLAG_NEW_ACCOUNT;
  } else if (input->account_age_days < 180) {
    score += 10;
    flags |= BANK_RISK_FLAG_NEW_ACCOUNT;
  }

  if (input->failed_attempts_24h >= 3) {
    score += 30;
    flags |= BANK_RISK_FLAG_FAILED_ATTEMPTS;
  } else if (input->failed_attempts_24h > 0) {
    score += 15;
    flags |= BANK_RISK_FLAG_FAILED_ATTEMPTS;
  }

  if (input->foreign_country != 0) {
    score += 20;
    flags |= BANK_RISK_FLAG_FOREIGN_COUNTRY;
  }

  if (input->night_time != 0) {
    score += 10;
    flags |= BANK_RISK_FLAG_NIGHT_TIME;
  }

  if (score > 100) {
    score = 100;
  }

  output->score = score;
  output->reason_flags = flags;
  if (score >= 70) {
    output->decision = BANK_RISK_DECISION_BLOCK;
  } else if (score >= 35) {
    output->decision = BANK_RISK_DECISION_REVIEW;
  } else {
    output->decision = BANK_RISK_DECISION_APPROVE;
  }

  return BANK_OK;
}

FFI_PLUGIN_EXPORT int32_t bank_update_galaxy_particles(
    float* particles,
    int32_t particle_count,
    float dt_seconds,
    float center_pull,
    float swirl,
    float damping,
    float escape_radius,
    float respawn_radius) {
  return bank_update_galaxy_particles_batched(
      particles,
      particle_count,
      dt_seconds,
      center_pull,
      swirl,
      damping,
      escape_radius,
      respawn_radius,
      1);
}

FFI_PLUGIN_EXPORT int32_t bank_update_galaxy_particles_batched(
    float* particles,
    int32_t particle_count,
    float dt_seconds,
    float center_pull,
    float swirl,
    float damping,
    float escape_radius,
    float respawn_radius,
    int32_t substeps) {
  if (particles == 0) {
    return BANK_ERR_NULL_POINTER;
  }

  if (particle_count < 0 ||
      substeps <= 0 ||
      dt_seconds <= 0.0f ||
      center_pull <= 0.0f ||
      swirl <= 0.0f ||
      damping <= 0.0f ||
      escape_radius <= 0.0f ||
      respawn_radius <= 0.0f) {
    return BANK_ERR_INVALID_ARGUMENT;
  }

  for (int32_t step = 0; step < substeps; step++) {
    bank_update_galaxy_particles_once(
        particles,
        particle_count,
        dt_seconds,
        center_pull,
        swirl,
        damping,
        escape_radius,
        respawn_radius);
  }

  return BANK_OK;
}

FFI_PLUGIN_EXPORT const char* bank_error_message(int32_t code) {
  switch (code) {
    case BANK_OK:
      return "ok";
    case BANK_ERR_NULL_POINTER:
      return "native pointer must not be null";
    case BANK_ERR_INVALID_ARGUMENT:
      return "native argument is outside the accepted range";
    default:
      return "unknown native error";
  }
}
