<?php

		namespace WhichBrowser\Data;

		use WhichBrowser\Constants\DeviceType;

		DeviceModels::$TIZEN_MODELS = [
			'Baltic'									=> [ 'Samsung', '"Baltic"' ],
			'SM-HIGGS'									=> [ 'Samsung', '"Higgs"' ],
			'KIRAN'										=> [ 'Samsung', 'Z1' ],
			'GT-I8800!'									=> [ 'Samsung', '"Melius"' ],
			'GT-I8805!'									=> [ 'Samsung', '"Redwood"' ],
			'GT-I9500!'									=> [ 'Samsung', 'GT-I9500 prototype' ],
			'SGH-N099'									=> [ 'Samsung', 'SGH-N099 prototype' ],
			'(ARMV7 )?SM-Z9005!'						=> [ 'Samsung', 'SM-Z9005 prototype' ],
			'Mobile-RD-PQ'								=> [ 'Samsung', 'RD-PQ prototype' ],
			'TM1'										=> [ 'Samsung', 'TM1 prototype' ],
			'SM-Z130!'									=> [ 'Samsung', 'Z1' ],
			'TIZEN SM-Z130!'							=> [ 'Samsung', 'Z1' ],
			'SM-Z300!'									=> [ 'Samsung', 'Z3' ],
			'TIZEN SM-Z300!'							=> [ 'Samsung', 'Z3' ],
			'SM-Z500!'									=> [ 'Samsung', 'SM-Z500' ],
			'SM-Z700!'									=> [ 'Samsung', 'SM-Z700' ],
			'SM-Z900!'									=> [ 'Samsung', 'Z' ],	
			'SM-Z910!'									=> [ 'Samsung', 'Z' ],
			'Z3 Z910F'									=> [ 'Samsung', 'Z' ],
			'SEC SC-001'								=> [ 'Samsung', 'SC-001 prototype' ],
			'SEC SC-03F'								=> [ 'Samsung', 'ZeQ' ],						// Unreleased version for DoCoMo
			'SC-03F'									=> [ 'Samsung', 'ZeQ' ],						// Unreleased version for DoCoMo

			'SM-R750!'									=> [ 'Samsung', 'Gear S', DeviceType::WATCH ],

			'NX300'										=> [ 'Samsung', 'NX300', DeviceType::CAMERA ],

			'hawkp'										=> [ 'Samsung', '"Hawkp"', DeviceType::TELEVISION ],

			'xu3'										=> [ 'Hardkernel', 'ODROID-XU3 developer board' ],

//			'FamilyHub'									=> [ 'Samsung', 'FamilyHub' ],

			'sdk'										=> [ null, null, DeviceType::EMULATOR ],
			'Emulator'									=> [ null, null, DeviceType::EMULATOR ],
			'Mobile-Emulator'							=> [ null, null, DeviceType::EMULATOR ],
			'TIZEN Emulator'							=> [ null, null, DeviceType::EMULATOR ],
		];