#ifndef BANK_CORE_FFI_H_
#define BANK_CORE_FFI_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#if _WIN32
#define FFI_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FFI_PLUGIN_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

#define BANK_OK 0
#define BANK_ERR_NULL_POINTER -1
#define BANK_ERR_INVALID_ARGUMENT -2

#define BANK_RISK_DECISION_APPROVE 0
#define BANK_RISK_DECISION_REVIEW 1
#define BANK_RISK_DECISION_BLOCK 2

#define BANK_RISK_FLAG_HIGH_AMOUNT 1
#define BANK_RISK_FLAG_NEW_ACCOUNT 2
#define BANK_RISK_FLAG_FAILED_ATTEMPTS 4
#define BANK_RISK_FLAG_FOREIGN_COUNTRY 8
#define BANK_RISK_FLAG_NIGHT_TIME 16
#define BANK_GALAXY_PARTICLE_STRIDE 4

typedef struct BankTransactionRiskInput {
  int32_t amount_cents;
  int32_t account_age_days;
  int32_t failed_attempts_24h;
  int32_t foreign_country;
  int32_t night_time;
} BankTransactionRiskInput;

typedef struct BankRiskScore {
  int32_t score;
  int32_t decision;
  int32_t reason_flags;
} BankRiskScore;

FFI_PLUGIN_EXPORT int32_t bank_add(int32_t a, int32_t b);
FFI_PLUGIN_EXPORT int32_t bank_validate_pan(const char* pan);
FFI_PLUGIN_EXPORT int32_t bank_validate_iban(const char* iban);
FFI_PLUGIN_EXPORT int32_t bank_score_transaction(
    const BankTransactionRiskInput* input,
    BankRiskScore* output);
FFI_PLUGIN_EXPORT int32_t bank_update_galaxy_particles(
    float* particles,
    int32_t particle_count,
    float dt_seconds,
    float center_pull,
    float swirl,
    float damping,
    float escape_radius,
    float respawn_radius);
FFI_PLUGIN_EXPORT const char* bank_error_message(int32_t code);

#ifdef __cplusplus
}
#endif

#endif
