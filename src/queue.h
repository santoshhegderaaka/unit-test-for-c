#ifndef QUEUE_H
#define QUEUE_H

#include <stdint.h>
#include <stdbool.h>

#define QUEUE_MAX_SIZE 32

typedef struct {
    uint8_t data[QUEUE_MAX_SIZE];
    uint32_t head;
    uint32_t tail;
    uint32_t count;
    uint32_t max_size;
} queue_t;

// Function declarations
void queue_init(queue_t* queue, uint32_t size);
bool queue_enqueue(queue_t* queue, uint8_t item);
bool queue_dequeue(queue_t* queue, uint8_t* item);
bool queue_is_empty(const queue_t* queue);
bool queue_is_full(const queue_t* queue);
uint32_t queue_size(const queue_t* queue);
void queue_clear(queue_t* queue);

#endif // QUEUE_H