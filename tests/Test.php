<?php
class Test extends PHPUnit_Framework_TestCase
{
  # Will need to add encrypted secrets via https://docs.travis-ci.com/user/encryption-keys/
	public function testOnePlusOne() {
		$this->assertEquals(1+1,1);
  }
}
?>