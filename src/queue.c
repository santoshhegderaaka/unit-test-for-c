#include "queue.h"
#include <string.h>

void queue_init(queue_t* queue, uint32_t size) {
    if (!queue || size > QUEUE_MAX_SIZE) {
        return;
    }
    
    queue->head = 0;
    queue->tail = 0;
    queue->count = 0;
    queue->max_size = size;
    memset(queue->data, 0, sizeof(queue->data));
}

bool queue_enqueue(queue_t* queue, uint8_t item) {
    if (!queue || queue_is_full(queue)) {
        return false;
    }
    
    queue->data[queue->tail] = item;
    queue->tail = (queue->tail + 1) % queue->max_size;
    queue->count++;
    return true;
}

bool queue_dequeue(queue_t* queue, uint8_t* item) {
    if (!queue || !item || queue_is_empty(queue)) {
        return false;
    }
    
    *item = queue->data[queue->head];
    queue->head = (queue->head + 1) % queue->max_size;
    queue->count--;
    return true;
}

bool queue_is_empty(const queue_t* queue) {
    return queue ? (queue->count == 0) : true;
}

bool queue_is_full(const queue_t* queue) {
    return queue ? (queue->count >= queue->max_size) : false;
}

uint32_t queue_size(const queue_t* queue) {
    return queue ? queue->count : 0;
}

void queue_clear(queue_t* queue) {
    if (queue) {
        queue->head = 0;
        queue->tail = 0;
        queue->count = 0;
    }
}