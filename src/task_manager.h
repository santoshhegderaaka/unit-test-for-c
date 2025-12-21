#ifndef TASK_MANAGER_H
#define TASK_MANAGER_H

#include <stdint.h>
#include <stdbool.h>

#define MAX_TASKS 10
#define TASK_NAME_LEN 16

typedef enum {
    TASK_READY,
    TASK_RUNNING,
    TASK_BLOCKED,
    TASK_SUSPENDED
} task_state_t;

typedef struct {
    uint32_t task_id;
    char name[TASK_NAME_LEN];
    task_state_t state;
    uint32_t priority;
    uint32_t stack_size;
} task_t;

// Function declarations
bool task_create(uint32_t id, const char* name, uint32_t priority, uint32_t stack_size);
bool task_delete(uint32_t id);
task_t* task_get(uint32_t id);
bool task_set_state(uint32_t id, task_state_t state);
uint32_t task_get_count(void);
void task_manager_init(void);

#endif // TASK_MANAGER_H