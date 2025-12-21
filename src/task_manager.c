#include "task_manager.h"
#include <string.h>
#include <stdio.h>

static task_t tasks[MAX_TASKS];
static uint32_t task_count = 0;

void task_manager_init(void) {
    memset(tasks, 0, sizeof(tasks));
    task_count = 0;
}

bool task_create(uint32_t id, const char* name, uint32_t priority, uint32_t stack_size) {
    if (task_count >= MAX_TASKS || !name) {
        return false;
    }
    
    // Check if task ID already exists
    for (uint32_t i = 0; i < task_count; i++) {
        if (tasks[i].task_id == id) {
            return false;
        }
    }
    
    tasks[task_count].task_id = id;
    strncpy(tasks[task_count].name, name, TASK_NAME_LEN - 1);
    tasks[task_count].name[TASK_NAME_LEN - 1] = '\0';
    tasks[task_count].state = TASK_READY;
    tasks[task_count].priority = priority;
    tasks[task_count].stack_size = stack_size;
    
    task_count++;
    return true;
}

bool task_delete(uint32_t id) {
    for (uint32_t i = 0; i < task_count; i++) {
        if (tasks[i].task_id == id) {
            // Shift remaining tasks
            for (uint32_t j = i; j < task_count - 1; j++) {
                tasks[j] = tasks[j + 1];
            }
            task_count--;
            return true;
        }
    }
    return false;
}

task_t* task_get(uint32_t id) {
    for (uint32_t i = 0; i < task_count; i++) {
        if (tasks[i].task_id == id) {
            return &tasks[i];
        }
    }
    return NULL;
}

bool task_set_state(uint32_t id, task_state_t state) {
    task_t* task = task_get(id);
    if (task) {
        task->state = state;
        return true;
    }
    return false;
}

uint32_t task_get_count(void) {
    return task_count;
}