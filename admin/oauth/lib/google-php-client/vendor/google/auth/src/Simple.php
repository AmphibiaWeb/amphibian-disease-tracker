<?php
/*
 * Copyright 2015 Google Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

namespace Google\Auth;

use GuzzleHttp\Collection;
use GuzzleHttp\Event\RequestEvents;
use GuzzleHttp\Event\SubscriberInterface;
use GuzzleHttp\Event\BeforeEvent;

/**
 * Simple is a Guzzle Subscriber that implements Google's Simple API access.
 *
 * Requests are accessed using the Simple API access developer key.
 */
class Simple implements SubscriberInterface
{
  /** @var configuration */
  private $config;

  /**
   * Create a new Simple plugin.
   *
   * The configuration array expects one option
   * - key: required, otherwise InvalidArgumentException is thrown
   *
   * @param array $config Configuration array
   */
  public function __construct(array $config)
  {
    $this->config = Collection::fromConfig($config, [], ['key']);
  }

  /* Implements SubscriberInterface */
  public function getEvents()
  {
    return ['before' => ['onBefore', RequestEvents::SIGN_REQUEST]];
  }

  /**
   * Updates the request query with the developer key if auth is set to simple
   *
   *   use GuzzleHttp\Client;
   *   use Google\Auth\Simple;
   *
   *   $my_key = 'is not the same as yours';
   *   $simple = new Simple(['key' => $my_key]);
   *   $client = new Client([
   *      'base_url' => 'https://www.googleapis.com/discovery/v1/',
   *      'defaults' => ['auth' => 'simple']
   *   ]);
   *
   *   $res = $client->get('drive/v2/rest');
   */
  public function onBefore(BeforeEvent $event)
  {
    // Requests using "auth"="simple" with the developer key.
    $request = $event->getRequest();
    if ($request->getConfig()['auth'] != 'simple') {
      return;
    }
    $request->getQuery()->overwriteWith($this->config);
  }
}
