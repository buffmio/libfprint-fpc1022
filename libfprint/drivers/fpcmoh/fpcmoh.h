/*
 * FPC MOH (Match-on-Host) driver for libfprint
 *
 * Supports FPC Disum USB fingerprint sensors (10a5:9200, 10a5:9201).
 *
 * Copyright (c) 2026 Sergey Subbotin <ssubbotin@gmail.com>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#pragma once

#include "fpi-image-device.h"
#include "fpi-ssm.h"
#include "fpi-usb-transfer.h"

#include <openssl/ssl.h>
#include <openssl/evp.h>

/* USB parameters */
#define FPCMOH_EP_IN (2 | FPI_USB_ENDPOINT_IN)              /* 0x82 */
#define FPCMOH_EP_IN_MAX_BUF_SIZE 2048
#define FPCMOH_CTRL_TIMEOUT 2000
#define FPCMOH_DATA_TIMEOUT 15000
#define FPCMOH_FINGER_TIMEOUT 600000      /* 10 min for finger wait */
#define FPCMOH_BULK_MAX_PKT 64

/* Sensor image dimensions (FPC1022: 112x88, 1 byte per pixel) */
#define FPCMOH_IMG_WIDTH 112
#define FPCMOH_IMG_HEIGHT 88
#define FPCMOH_IMG_BPP 1
#define FPCMOH_IMG_SIZE (FPCMOH_IMG_WIDTH * FPCMOH_IMG_HEIGHT * FPCMOH_IMG_BPP)
#define FPCMOH_IMG_PIXELS (FPCMOH_IMG_WIDTH * FPCMOH_IMG_HEIGHT)
#define FPCMOH_IMG_SCALE 2

/* TLS inner message header size (cmdid + total_len + metadata) */
#define FPCMOH_TLS_MSG_HDR_SIZE 24

/* USB control transfer request types */
#define FPCMOH_HOST_TO_DEVICE 0x40
#define FPCMOH_DEVICE_TO_HOST 0xC0

/* Commands (bRequest in USB control transfer) */
#define FPCMOH_CMD_INIT 0x01
#define FPCMOH_CMD_ARM 0x02
#define FPCMOH_CMD_ABORT 0x03
#define FPCMOH_CMD_TLS_INIT 0x05
#define FPCMOH_CMD_TLS_DATA 0x06
#define FPCMOH_CMD_INDICATE_S_STATE 0x08
#define FPCMOH_CMD_GET_IMG 0x09
#define FPCMOH_CMD_GET_TLS_KEY 0x0B
#define FPCMOH_CMD_GET_KPI 0x0C
#define FPCMOH_CMD_FINGERPRINT_OFF 0x12
#define FPCMOH_CMD_END_ENROL 0x13
#define FPCMOH_CMD_REFRESH_SENSOR 0x20
#define FPCMOH_CMD_GET_FW_VERSION 0x30
#define FPCMOH_CMD_GET_HW_UNIQUE_ID 0x31
#define FPCMOH_CMD_FLUSH_KEYS 0x32
#define FPCMOH_CMD_GET_STATE 0x50

/* Events (code field in bulk IN event header) */
#define FPCMOH_EVT_HELLO 0x01
#define FPCMOH_EVT_INIT_RESULT 0x02
#define FPCMOH_EVT_ARM_RESULT 0x03
#define FPCMOH_EVT_DEAD_PIXEL_REPORT 0x04
#define FPCMOH_EVT_TLS 0x05
#define FPCMOH_EVT_FINGER_DOWN 0x06
#define FPCMOH_EVT_FINGER_UP 0x07
#define FPCMOH_EVT_IMAGE 0x08
#define FPCMOH_EVT_USB_LOGS 0x09
#define FPCMOH_EVT_TLS_KEY 0x0A
#define FPCMOH_EVT_REFRESH_SENSOR 0x20

/* TLS key packet magic */
#define FPCMOH_TLS_KEY_MAGIC 0x0DEC0DED

/* Derived PSK size: SHA-256 output */
#define FPCMOH_TLS_PSK_SIZE 32

/* AES-256-CBC block size, used to sanity-check the sealed key length */
#define FPCMOH_AES_BLOCK_SIZE 16

/* S-state values */
#define FPCMOH_S_STATE_S0 0x0010
#define FPCMOH_S_STATE_SX 0x0011

/* Sensor init/arm/stop data (4-byte payloads for CMD_INIT and CMD_ARM) */
#define FPCMOH_INIT_DATA_SIZE 4
#define FPCMOH_ARM_OP_INIT 0x10
#define FPCMOH_ARM_OP_START 0x11
#define FPCMOH_ARM_OP_STOP 0x12

/* SIGFM matching threshold (minimum number of consistent keypoint matches) */
#define FPCMOH_SCORE_THRESHOLD 10

/* Event header (received on bulk IN endpoint) - network byte order */
typedef struct __attribute__((packed))
{
  guint32 code;
  guint32 len;
  guint32 unknown;
} FpcMohEvtHdr;

/* TLS key packet header (all offsets are from start of packet) */
typedef struct __attribute__((packed))
{
  guint32 magic;
  guint32 key_offset;
  guint32 key_len;
  guint32 aad_offset;
  guint32 aad_len;
  guint32 sig_offset;
  guint32 sig_len;
} FpcMohTlsKeyPkt;

/* SSM states for device open */
typedef enum {
  FPCMOH_OPEN_INDICATE_S_STATE = 0,
  FPCMOH_OPEN_GET_STATE,
  FPCMOH_OPEN_PARSE_STATE,
  FPCMOH_OPEN_CMD_INIT,
  FPCMOH_OPEN_WAIT_INIT_RESULT,
  FPCMOH_OPEN_GET_TLS_KEY,
  FPCMOH_OPEN_PARSE_TLS_KEY,
  FPCMOH_OPEN_TLS_INIT,
  FPCMOH_OPEN_TLS_HANDSHAKE,
  FPCMOH_OPEN_NUM_STATES,
} FpcMohOpenState;

/* SSM states for image capture */
typedef enum {
  FPCMOH_CAPTURE_STOP_ARM = 0,
  FPCMOH_CAPTURE_STOP_ABORT,
  FPCMOH_CAPTURE_STOP_SESSION_OFF,
  FPCMOH_CAPTURE_ARM_SENSOR,
  FPCMOH_CAPTURE_WAIT_FINGER,
  FPCMOH_CAPTURE_GET_IMAGE,
  FPCMOH_CAPTURE_RECV_IMAGE,
  FPCMOH_CAPTURE_NUM_STATES,
} FpcMohCaptureState;

/* SSM states for deactivate */
typedef enum {
  FPCMOH_DEACT_ARM_STOP = 0,
  FPCMOH_DEACT_ABORT,
  FPCMOH_DEACT_SESSION_OFF,
  FPCMOH_DEACT_NUM_STATES,
} FpcMohDeactState;

G_DECLARE_FINAL_TYPE (FpiDeviceFpcMoh, fpi_device_fpcmoh, FPI,
                      DEVICE_FPCMOH, FpImageDevice)

struct _FpiDeviceFpcMoh
{
  FpImageDevice parent;

  /* USB bulk event reception */
  guint8 bulk_buf[FPCMOH_EP_IN_MAX_BUF_SIZE];
  gsize  bulk_recv_len;
  gsize  evt_total_len;

  /* TLS */
  guint8   tls_psk[FPCMOH_TLS_PSK_SIZE];
  gsize    tls_psk_len;
  SSL_CTX *ssl_ctx;
  SSL     *ssl;
  BIO     *bio_in;       /* we write device data here, SSL reads from it */
  BIO     *bio_out;      /* SSL writes here, we read and send to device */
  gboolean tls_established;

  /* Image buffer */
  guint8  *img_buf;
  gsize    img_recv_len;
  gsize    img_expected_len;      /* actual payload size from TLS message header */
  gboolean tls_in_image;         /* currently accumulating image payload from TLS */

  /* State */
  FpiSsm       *open_ssm;
  FpiSsm       *capture_ssm;
  gboolean      deactivating;
  GCancellable *interrupt_cancellable;
};
