/*
 * The MIT License (MIT)
 *
 * Copyright (c) 2024 Masafumi
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef _EBYTE_E104_BT5040U_H
#define _EBYTE_E104_BT5040U_H

#define _PINNUM(port, pin) ((port)*32 + (pin))

/*------------------------------------------------------------------*/
/* LED
 *------------------------------------------------------------------*/
#define LEDS_NUMBER 2

// Pin No.38 LED1 Red   P0.08
//                Green P1.09 (?? not color LED)
//                Blue  P0.12 (?? not color LED)
// Pin No.39 LED  Red   P0.06

#define LED_PRIMARY_PIN      _PINNUM(0, 6)    // LED  Red
#define LED_SECONDARY_PIN    _PINNUM(0, 8)    // LED1 Red
#define LED_STATE_ON         0

/*------------------------------------------------------------------*/
/* BUTTON
 *------------------------------------------------------------------*/

// Pin No.36 RST REST
// Pin No.37 SW  P1.06

#define BUTTONS_NUMBER       2
#define BUTTON_1             _PINNUM(0, 18) // unusable: RESET
#define BUTTON_2             _PINNUM(1, 6)  // SW
#define BUTTON_PULL          NRF_GPIO_PIN_PULLUP

//--------------------------------------------------------------------+
// BLE OTA
//--------------------------------------------------------------------+
#define BLEDIS_MANUFACTURER  "CDEBYTE"
#define BLEDIS_MODEL         "E104-BT5040U"

//--------------------------------------------------------------------+
// USB
//--------------------------------------------------------------------+
#define USB_DESC_VID          0x239A
#define USB_DESC_UF2_PID      0x00EB
#define USB_DESC_CDC_ONLY_PID 0x00EB

//--------------------------------------------------------------------+
// UF2
//--------------------------------------------------------------------+
#define UF2_PRODUCT_NAME      "Ebyte E104-BT5040U"
#define UF2_VOLUME_LABEL      "BT5040U"
#define UF2_BOARD_ID          "nRF52840-Ebyte-E104-BT5040U"
#define UF2_INDEX_URL         "https://www.cdebyte.com/products/E104-BT5040U"

#endif // _EBYTE_E104_BT5040U_H
