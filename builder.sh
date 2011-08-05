#!/bin/bash

echo Building $BUILDER_COMPONENT
exec builder/$BUILDER_COMPONENT.sh
