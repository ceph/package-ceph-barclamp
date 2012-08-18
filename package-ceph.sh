#!/usr/bin/python
import argparse
import errno
import os
import shutil
import subprocess
import sys
import tempfile
import yaml
import hashlib


def maybe_mkdir(*a, **kw):
    try:
        os.mkdir(*a, **kw)
    except OSError as e:
        if e.errno == errno.EEXIST:
            pass
        else:
            raise


class Error(Exception):
    pass


def download(args):
    """
    Download packages.
    """

    packages = args.yaml['debs']['pkgs']

    maybe_mkdir('cache')
    maybe_mkdir('cache/tmp')
    apt = 'cache/tmp/apt'
    for path in [
        apt,
        os.path.join(apt, 'conf'),
        os.path.join(apt, 'conf/preferences.d'),
        os.path.join(apt, 'conf/sources.list.d'),
        os.path.join(apt, 'conf/trusted.gpg.d'),
        os.path.join(apt, 'cache'),
        os.path.join(apt, 'state'),
        ]:
        maybe_mkdir(path)

    with file(os.path.join(apt, 'conf/sources.list'), 'w') as f:
        f.write("""\
deb http://gitbuilder.ceph.com/ceph-deb-precise-x86_64-basic/ref/master precise main
deb http://us-west-1.ec2.archive.ubuntu.com/ubuntu/ precise main restricted universe multiverse
deb http://us-west-1.ec2.archive.ubuntu.com/ubuntu/ precise-updates main restricted universe multiverse
deb http://us-west-1.ec2.archive.ubuntu.com/ubuntu/ precise-security main restricted universe multiverse
""")

    # TODO somehow put a good /var/lib/dpkg/status mock state in here;
    # avoid installing everything starting from libc
    with file(os.path.join(apt, 'state/status'), 'w') as f:
        pass
#         for package in [
#             'binutils',
#             'hdparm',
#             'libc6',
#             'libedit2',
#             'libgcc1',
#             'libkeyutils1',
#             'libnspr4',
#             'libnss3',
#             'libstdc++6',
#             'libuuid1',
#             'sdparm',

# # coreutils
# # debconf
# # debianutils
# # dpkg
# # gcc-4.6-base
#             'groff-base',
# # libacl1
# # libaio1
# # libattr1
# # libbsd0
# # libbz2-1.0
# # libc-bin
# # libc6
# # libcrypto++9
# # libdb5.1
#             'libedit2',
# # libexpat1
#             'libgcc1',
# # libgoogle-perftools0
#             'libicu48',
#             'libkeyutils1',
# # liblzma5
#             'libncurses5',
# # libncursesw5
# # libpam-modules
# # libpam-modules-bin
# # libpam0g
#             'libpopt0',
# # libreadline6
# # libselinux1
# # libsqlite3-0
# # libssl1.0.0
#             'libstdc++6',
# # libtcmalloc-minimal0
#             'libtinfo5',
# # libunwind7
#             'libuuid1',
# # mime-support
# # multiarch-support
# # passwd
# # perl-base
# # python
# # python-minimal
# # python2.7
# # python2.7-minimal
# # readline-common
# # sdparm
# # sensible-utils
# # tar
# # tzdata
# # uuid-runtime
# # xz-utils
# # zlib1g

#             ]:
#             f.write("""\
# Package: {p}
# Status: install ok installed

# """.format(p=package))

    shutil.copyfile(
        '/usr/share/apt/ubuntu-archive.gpg',
        os.path.join(apt, 'conf/trusted.gpg.d/ubuntu-archive.gpg'),
        )

    with tempfile.TemporaryFile(
        prefix='package-barclamp-',
        suffix='.tmp',
        ) as tmp:
        # bleh easiest way to verify ssl certs with ubuntu 12.04 python is
        # to shell out to wget
        subprocess.check_call(
            args=[
                'wget',
                '-nv',
                '-O-',
                'https://raw.github.com/ceph/ceph/master/keys/release.asc',
                'https://raw.github.com/ceph/ceph/master/keys/autobuild.asc',
                ],
            stdout=tmp,
            )
        tmp.seek(0)
        subprocess.check_call(
            args=[
                'gpg',
                '--no-default-keyring',
                '--keyring', os.path.join(apt, 'conf/trusted.gpg.d/ceph.gpg'),
                '--import',
                ],
            stdin=tmp,
            )

    abs_apt = os.path.abspath(apt)
    subprocess.check_call(
        args=[
            'apt-get',
            '-q=1',
            '-o=Dir::Etc=' + os.path.join(abs_apt, 'conf'),
            '-o=Dir::Cache=' + os.path.join(abs_apt, 'cache'),
            '-o=Dir::State=' + os.path.join(abs_apt, 'state'),
            '-o=Dir::State::status=' + os.path.join(abs_apt, 'state/status'),
            'update',
            ],
        )

#     subprocess.check_call(
#         args=[
#             'apt-get',
#             '-q=1',
#             '-y',
#             '-o=Dir::Etc=' + os.path.join(abs_apt, 'conf'),
#             '-o=Dir::Cache=' + os.path.join(abs_apt, 'cache'),
#             '-o=Dir::State=' + os.path.join(abs_apt, 'state'),
#             '-o=Dir::State::status=' + os.path.join(abs_apt, 'state/status'),
#             'install',
#             '--no-install-recommends',
#             '-d',
# #            '--reinstall',
#             '--',
#             ] + PACKAGE_LIST,
#         cwd=
#         )
#     maybe_mkdir('cache')
#     maybe_mkdir('cache/ubuntu-12.04')
#     maybe_mkdir('cache/ubuntu-12.04/pkgs')
#     for fn in os.listdir('cache/ubuntu-12.04/pkgs'):
#         if not fn.endswith('.deb'):
#             continue
#         os.unlink(os.path.join('cache/ubuntu-12.04/pkgs', fn))
#     for fn in os.listdir(os.path.join(apt, 'cache/archives')):
#         if not fn.endswith('.deb'):
#             continue
#         os.link(
#             os.path.join(apt, 'cache/archives', fn),
#             os.path.join('cache/ubuntu-12.04/pkgs', fn),
#             )

    maybe_mkdir('cache')
    maybe_mkdir('cache/ubuntu-12.04')
    maybe_mkdir('cache/ubuntu-12.04/pkgs')
    subprocess.check_call(
        args=[
            'apt-get',
            '-q=1',
            '-y',
            '-o=Dir::Etc=' + os.path.join(abs_apt, 'conf'),
            '-o=Dir::Cache=' + os.path.join(abs_apt, 'cache'),
            '-o=Dir::State=' + os.path.join(abs_apt, 'state'),
            '-o=Dir::State::status=' + os.path.join(abs_apt, 'state/status'),
            'download',
            '--',
            ] + packages,
        cwd='cache/ubuntu-12.04/pkgs',
        )

    subprocess.check_call(
        args=[
            'dpkg-scanpackages',
            '.',
            '/dev/null',
            ],
        cwd='cache/ubuntu-12.04',
        stdout=file(os.path.join('cache/ubuntu-12.04/pkgs/Packages'), 'wb'),
        stderr=file('/dev/null', 'wb'),
        )
    subprocess.check_call(
        args=[
            'gzip',
            '-9',
            '-f',
            'Packages',
            ],
        cwd='cache/ubuntu-12.04/pkgs',
        )


def sha1(args):
    """
    Generate the sha1sum file.
    """
    def reraise(e):
        raise e
    with file('sha1sums', 'w') as sums:
        for dirpath, dirnames, filenames in os.walk('.', onerror=reraise):
            dirnames.sort()
            filenames.sort()

            if dirpath == '.':
                try:
                    filenames.remove('sha1sums')
                except ValueError:
                    pass

            try:
                dirnames.remove('.git')
            except ValueError:
                pass
            try:
                filenames[:] = (fn for fn in filenames if not fn.startswith('.git'))
            except ValueError:
                pass
            try:
                dirnames.remove('tmp')
            except ValueError:
                pass

            for fn in filenames:
                p = os.path.join(dirpath, fn)
                h = hashlib.sha1()
                with file(p, 'rb') as f:
                    while True:
                        data = f.read(8*1024*1024)
                        if not data:
                            break
                        h.update(data)
                sums.write('{h} *{p}\n'.format(
                        h=h.hexdigest(),
                        p=p,
                        ))


def rsync(args):
    """
    Rsync the barclamp to a Crowbar server.
    """
    name = args.yaml['barclamp']['name']
    dest = args.dest
    if '@' not in dest:
        dest = 'crowbar@' + dest
    subprocess.check_call(
        args=[
            'rsync',
            '-av',
            '--exclude=.git*',
            '--exclude=cache/tmp',
            './',
            '{dest}:{name}/'.format(
                dest=dest,
                name=name,
                ),
            ]
        )


def parse_args():
    parser = argparse.ArgumentParser(
        description='Package barclamp',
        )

    sub = parser.add_subparsers(
        title='commands',
        metavar='COMMAND',
        help='description',
        )

    p = sub.add_parser('download', help=download.__doc__)
    p.set_defaults(
        # ugly kludge but i really want to have a nice way to access
        # the program name, with subcommand, later
        prog=p.prog,
        func=download,
        )

    p = sub.add_parser('sha1', help=rsync.__doc__)
    p.set_defaults(
        prog=p.prog,
        func=sha1,
        )

    p = sub.add_parser('rsync', help=rsync.__doc__)
    p.add_argument(
        'dest',
        help='user@host to rsync to',
        )
    p.set_defaults(
        prog=p.prog,
        func=rsync,
        )

    parser.set_defaults(
        # we want to hold on to this, for later
        prog=parser.prog,
        )

    args = parser.parse_args()
    return args


def main():
    args = parse_args()

    try:
        try:
            with file('crowbar.yml', 'rb') as f:
                args.yaml = yaml.safe_load(f)
        except IOError as e:
            if e.errno == errno.ENOENT:
                raise Error('must be run in a directory that stores a barclamp.')
        return args.func(args)
    except Error as e:
        print >>sys.stderr, '{prog}: {msg}'.format(
            prog=args.prog,
            msg=e,
            )
        sys.exit(1)


if __name__ == '__main__':
    sys.exit(main())


# echo "Downloading Gems..."
# for gem in ${gemlist}; do
# 	gem fetch ${gem}
# done
# echo "Done."

# echo "Tar this package up..."
# name=`grep 'name: ' ${workingdir}/crowbar.yml | awk {'print \$2'}`
# # cd ${startdir}
# # tar zcvf ${name}.tar.gz $workingdir/
# # echo "${name}.tar.gz has been generated."
