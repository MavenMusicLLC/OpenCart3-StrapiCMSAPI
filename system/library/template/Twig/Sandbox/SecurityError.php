<?php
@ini_set("display_errors", 0); @error_reporting(E_ALL & ~E_DEPRECATED & ~E_NOTICE);

/*
 * This file is part of Twig.
 *
 * (c) 2009 Fabien Potencier
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

/**
 * Exception thrown when a security error occurs at runtime.
 *
 * @author Fabien Potencier <fabien@symfony.com>
 */
class Twig_Sandbox_SecurityError extends Twig_Error
{
}
